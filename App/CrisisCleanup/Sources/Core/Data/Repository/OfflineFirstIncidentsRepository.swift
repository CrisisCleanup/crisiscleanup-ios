import Combine
import Foundation

class OfflineFirstIncidentsRepository: IncidentsRepository {
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    let isLoading: any Publisher<Bool, Never>

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

    private let incidentsSubject = CurrentValueSubject<[Incident], Never>([])
    let incidents: any Publisher<[Incident], Never>

    private let dataSource: CrisisCleanupNetworkDataSource
    private let appPreferencesDataStore: AppPreferencesDataStore
    private let incidentDao: IncidentDao
    private let locationDao: LocationDao
    private let incidentOrganizationDao: IncidentOrganizationDao
    private let organizationsSyncer: OrganizationsSyncer
    private let logger: AppLogger

    private var statusLookup = [String: PopulatedWorkTypeStatus]()

    private var disposables = Set<AnyCancellable>()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        appPreferencesDataStore: AppPreferencesDataStore,
        incidentDao: IncidentDao,
        locationDao: LocationDao,
        incidentOrganizationDao: IncidentOrganizationDao,
        organizationsSyncer: OrganizationsSyncer,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.appPreferencesDataStore = appPreferencesDataStore
        self.incidentDao = incidentDao
        self.locationDao = locationDao
        self.incidentOrganizationDao = incidentOrganizationDao
        self.organizationsSyncer = organizationsSyncer
        logger = loggerFactory.getLogger("incidents")

        fullIncidentQueryFields = incidentsQueryFields + ["form_fields"]

        isLoading = isLoadingSubject
        incidents = incidentsSubject

        incidentDao.streamIncidents()
            .sink { completion in
            } receiveValue: {
                self.incidentsSubject.value = $0
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

    func streamIncident(_ id: Int64) -> any Publisher<Incident?, Never> {
        incidentDao.streamFormFieldsIncident(id)
            .assertNoFailure()
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
        isLoadingSubject.value = true
        do {
            defer { isLoadingSubject.value = false }

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
                            incident.id,
                            fullIncidentQueryFields
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
        if let networkIncident = try await dataSource.getIncident(id, fullIncidentQueryFields) {
            let incidents = [networkIncident]
            try await saveIncidentsPrimaryData(incidents)
            try await saveIncidentsSecondaryData(incidents)
        }
    }

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async {
        if !force {
            do {
                if let syncStats = try incidentOrganizationDao.getSyncStats(incidentId),
                   syncStats.targetCount > 0,
                   let syncedAt = syncStats.successfulSync,
                   syncedAt.addingTimeInterval(14.days) > Date.now,
                   syncStats.appBuildVersionCode >= IncidentOrganizationsStableModelBuildVersion {
                    return
                }
            } catch {
                logger.logError(error)
            }
        }

        do {
            try await organizationsSyncer.sync(incidentId)
        } catch {
            logger.logError(error)
        }
    }
}
