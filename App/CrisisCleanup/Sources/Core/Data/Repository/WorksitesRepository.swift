import Combine
import CoreLocation
import Foundation

public protocol WorksitesRepository {
    var isLoading: any Publisher<Bool, Never> { get }

    var syncWorksitesFullIncidentId: any Publisher<Int64, Never> { get }

    var isDeterminingWorksitesCount: any Publisher<Bool, Never> { get }

    func streamIncidentWorksitesCount(_ incidentIdStream: any Publisher<Int64, Never>) -> any Publisher<IncidentIdWorksiteCount, Never>

    func streamLocalWorksite(_ worksiteId: Int64) -> any Publisher<LocalWorksite?, Never>

    func getWorksite(_ id: Int64) async throws -> Worksite?

    func streamRecentWorksites(_ incidentId: Int64) -> any Publisher<[WorksiteSummary], Never>

    func getWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeWest: Double,
        longitudeEast: Double,
        limit: Int,
        offset: Int
    ) throws -> [WorksiteMapMark]

    func getWorksitesCount(_ incidentId: Int64) throws -> Int

    func getWorksitesCount(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeLeft: Double,
        longitudeRight: Double
    ) throws -> Int

    func refreshWorksites(
        _ incidentId: Int64,
        forceQueryDeltas: Bool,
        forceRefreshAll: Bool
    ) async throws

    func getWorksiteSyncStats(_ incidentId: Int64) throws -> IncidentDataSyncStats?

    func getLocalId(_ networkWorksiteId: Int64) throws -> Int64

    func syncNetworkWorksite(
        _ worksite: NetworkWorksiteFull,
        _ syncedAt: Date
    ) async throws -> Bool

    func pullWorkTypeRequests(_ networkWorksiteId: Int64) async throws

    func setRecentWorksite(
        incidentId: Int64,
        worksiteId: Int64,
        viewStart: Date
    )

    func getUnsyncedCounts(_ worksiteId: Int64) throws -> [Int]

    func shareWorksite(
        worksiteId: Int64,
        emails: [String],
        phoneNumbers: [String],
        shareMessage: String,
        noClaimReason: String?
    ) async -> Bool

    func getTableData(
        incidentId: Int64,
        filters: CasesFilter,
        sortBy: WorksiteSortBy,
        coordinates: CLLocationCoordinate2D?,
        searchRadius: Double,
        count: Int
    ) async throws -> [TableDataWorksite]
}

extension WorksitesRepository {
    func refreshWorksites(_ incidentId: Int64) async throws {
        try await refreshWorksites(
            incidentId,
            forceQueryDeltas: false,
            forceRefreshAll: false
        )
    }

    func syncNetworkWorksite(_ worksite: NetworkWorksiteFull) async throws -> Bool {
        return try await syncNetworkWorksite(worksite, Date())
    }

    func getTableData(
        incidentId: Int64,
        filters: CasesFilter,
        sortBy: WorksiteSortBy,
        coordinates: CLLocationCoordinate2D?
    ) async throws -> [TableDataWorksite] {
        try await getTableData(
            incidentId: incidentId,
            filters: filters,
            sortBy: sortBy,
            coordinates: coordinates,
            searchRadius: 100.0,
            count: 360
        )
    }
}
