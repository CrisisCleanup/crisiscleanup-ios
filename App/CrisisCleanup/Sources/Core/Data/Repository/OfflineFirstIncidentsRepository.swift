import Combine
import Foundation

class OfflineFirstIncidentsRepository: IncidentsRepository {
    @Published private var isLoadingStream = false
    lazy var isLoading = $isLoadingStream

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
    lazy var incidents = $incidentsStream

    private var incidentPublisher = Just<Incident?>(nil)

    private let dataSource: CrisisCleanupNetworkDataSource
    private let appPreferencesDataStore: AppPreferencesDataStore
    private let logger: AppLogger

    private var statusLookup = [String: PopulatedWorkTypeStatus]()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        appPreferencesDataStore: AppPreferencesDataStore,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.appPreferencesDataStore = appPreferencesDataStore
        logger = loggerFactory.getLogger("incidents")

        fullIncidentQueryFields = incidentsQueryFields + ["form_fields"]
    }

    func getIncidents(_ startAt: Date) async -> [Incident] {
        // TODO: Do
        return []
    }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) async -> Incident? {
        // TODO: Do
        return nil
    }

    func streamIncident(_ id: Int64) -> AnyPublisher<Incident?, Never> {
        // TODO: Do
        return incidentPublisher.eraseToAnyPublisher()
    }

    private func saveLocations(_ incidents: [NetworkIncident]) async throws {
        let incidentLocationLookup = incidents.associate { ($0.id, $0.locations ) }
        let locationIds = incidentLocationLookup.values.flatMap { $0.map { il in il.location } }

        let locations = try await dataSource.getIncidentLocations(locationIds)
        var locationLookup = [Int64: Location]()
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
            locationLookup = sourceLocations.associateBy { $0.id }
        }

        // TODO: Do
        print("location lookup", incidentLocationLookup)
        print("locations", locationLookup)
    }

    private func saveIncidentsSecondaryData(_ incidents: [NetworkIncident]) async throws {
        try await saveLocations(incidents)
    }

    private func syncInternal(forcePullAll: Bool = false) async throws {
        isLoadingStream = true
        do {
            defer { isLoadingStream = false }

            // TODO: Query count from database when ready
            let pullAll = forcePullAll || incidentsStream.count < 10

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

            let sortedIncidents = networkIncidents
                .sorted(by: { a, b in a.startAt >= b.startAt })
                .map { $0.asExternalModel() }

            incidentsStream = sortedIncidents

            try Task.checkCancellation()

            try await saveIncidentsSecondaryData(networkIncidents)

            // TODO Query locations as well

        }
    }

    func pullIncidents() async throws {
        var isSuccessful = false
        do {
            defer {
                // TODO: Test isSuccessful changes correctly on successful
                appPreferencesDataStore.setSyncAttempt(isSuccessful)
            }

            try await syncInternal()
            isSuccessful = true
        }
    }

    func pullIncident(id: Int64) async {
        // TODO: Do
    }

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async {
        // TODO: Do
    }
}
