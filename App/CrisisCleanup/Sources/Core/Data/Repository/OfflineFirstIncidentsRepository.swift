import Combine
import Foundation

class OfflineFirstIncidentsRepository: IncidentsRepository {
    @Published private var isLoadingStream = false
    lazy private(set) var isLoading = $isLoadingStream

    private let incidentsQueryFields = [
        "id",
        "start_at",
        "name",
        "short_name",
        "incident_type",
        "locations",
        "turn_on_release",
        "active_phone_number",
        "is_archived",
    ]
    private let fullIncidentQueryFields: [String]

    @Published private var incidentsStream: [Incident] = []
    lazy private(set) var incidents = $incidentsStream

    private let dataSource: CrisisCleanupNetworkDataSource
    private let appPreferencesDataStore: AppPreferencesDataStore
    private let incidentDao: IncidentDao
    private let locationDao: LocationDao
    private let logger: AppLogger

    private var statusLookup = [String: PopulatedWorkTypeStatus]()

    private var disposables = Set<AnyCancellable>()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        appPreferencesDataStore: AppPreferencesDataStore,
        incidentDao: IncidentDao,
        locationDao: LocationDao,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.appPreferencesDataStore = appPreferencesDataStore
        self.incidentDao = incidentDao
        self.locationDao = locationDao
        logger = loggerFactory.getLogger("incidents")

        fullIncidentQueryFields = incidentsQueryFields + ["form_fields"]

        incidentDao.streamIncidents()
            .receive(on: RunLoop.main)
            .sink { completion in
            } receiveValue: {
                self.incidentsStream = $0
            }
            .store(in: &disposables)
    }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) throws -> Incident? {
        loadFormFields
        ? try incidentDao.getFormFieldsIncident(id)
        : try incidentDao.getIncident(id)
    }

    func getIncidents(_ startAt: Date) throws -> [Incident] {
        try incidentDao.getIncidents(startAt)
    }

    func streamIncident(_ id: Int64) -> AnyPublisher<Incident?, Error> {
        incidentDao.streamFormFieldsIncident(id)
    }

    private func saveLocations(_ incidents: [NetworkIncident]) async throws {
        let locationIds = incidents.flatMap { $0.locations.map { il in il.location } }
        let locations = try await dataSource.getIncidentLocations(locationIds)
        if locations.isNotEmpty {
            let sourceLocations = locations.map {
                let multiCoordinates = $0.geom?.condensedCoordinates
                let coordinates = $0.poly?.condensedCoordinates ?? $0.point?.coordinates
                return Location(
                    id: $0.id,
                    shapeLiteral: $0.shapeType,
                    coordinates: multiCoordinates == nil ? coordinates : nil,
                    multiCoordinates: multiCoordinates
                )
            }
            try await locationDao.saveLocations(sourceLocations)
        }
    }

    private func saveIncidentsPrimaryData(_ incidents: [NetworkIncident]) async throws {
        try await incidentDao.saveIncidents(
            incidents.map { $0.asRecord },
            incidents.flatMap { $0.asLocationRecords },
            incidents.flatMap { $0.asIncidentToLocationRecords }
        )
    }

    private func saveFormFields(_ incidents: [NetworkIncident]) async throws {
        let incidentsFields = try incidents
            .filter { $0.fields?.isNotEmpty == true }
            .map {
                let incidentId = $0.id
                let fields = try $0.fields!.map { f in try f.asRecord(incidentId) }
                return (incidentId, fields)
            }
        try await incidentDao.updateFormFields(incidentsFields)
    }

    private func saveIncidentsSecondaryData(_ incidents: [NetworkIncident]) async throws {
        try await saveLocations(incidents)
        try await saveFormFields(incidents)
    }

    private func syncInternal(forcePullAll: Bool = false) async throws {
        isLoadingStream = true
        do {
            defer { isLoadingStream = false }

            var pullAll = forcePullAll
            if !pullAll {
                let localIncidentsCount = incidentDao.getIncidentCount()
                pullAll = localIncidentsCount < 10
            }

            let queryFields: [String]
            let pullAfter: Date?
            let recentTime = Date().addingTimeInterval(-120.days)
            if pullAll {
                queryFields = incidentsQueryFields
                pullAfter = nil
            } else {
                queryFields = fullIncidentQueryFields
                pullAfter = recentTime
            }
            let networkIncidents = try await dataSource.getIncidents(queryFields, pullAfter)

            if networkIncidents.isNotEmpty {
                try await saveIncidentsPrimaryData(networkIncidents)

                try Task.checkCancellation()

                let recentIncidents = networkIncidents.filter { $0.startAt > recentTime }
                try await saveIncidentsSecondaryData(recentIncidents)

                try Task.checkCancellation()

                let incidentsWithFields = networkIncidents.map({ $0.fields }).filter({ $0 != nil})
                if incidentsWithFields.isEmpty {
                    let ordered = networkIncidents.sorted { a, b in
                        a.startAt > b.startAt
                    }
                    let latestIncidents: [NetworkIncident] = Array(ordered[..<min(3, ordered.count)])
                    for incident in latestIncidents {
                        if let networkIncident = try await dataSource.getIncident(
                            id: incident.id,
                            fields: fullIncidentQueryFields
                        ) {
                            try await saveFormFields([networkIncident])
                        }
                    }
                }
            }
        }
    }

    func pullIncidents() async throws {
        var isSuccessful = false
        do {
            defer {
                appPreferencesDataStore.setSyncAttempt(isSuccessful)
            }

            try await syncInternal()
            isSuccessful = true
        }
    }

    func pullIncident(_ id: Int64) async throws {
        if let networkIncident = try await dataSource.getIncident(id: id, fields: fullIncidentQueryFields) {
            let incidents = [networkIncident]
            try await saveIncidentsPrimaryData(incidents)
            try await saveIncidentsSecondaryData(incidents)
        }
    }

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async throws {
        // TODO: Do
    }
}
