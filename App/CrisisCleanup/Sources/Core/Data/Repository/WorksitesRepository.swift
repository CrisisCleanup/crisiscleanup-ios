import Combine
import Foundation

public protocol WorksitesRepository {
    var isLoading: Published<Bool>.Publisher { get }

    var syncWorksitesFullIncidentId: Published<[Int64]>.Publisher { get }

    func streamWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeLeft: Double,
        longitudeRight: Double,
        limit: Int,
        offset: Int
    ) async throws -> Published<[[WorksiteMapMark]]>.Publisher

    /**
     * Stream of an incident's [Worksite]s
     */
    func streamWorksites(_ incidentId: Int64, _ limit: Int, _ offset: Int) throws -> Published<[Worksite]>.Publisher

    func streamIncidentWorksitesCount(_ id: Int64) throws -> Published<Int>.Publisher

    func streamLocalWorksite(_ worksiteId: Int64) throws -> Published<LocalWorksite?>.Publisher

    func streamRecentWorksites(_ incidentId: Int64) throws -> Published<[[WorksiteSummary]]>.Publisher

    func getWorksitesMapVisual(_ incidentId: Int64, _ limit: Int, _ offset: Int) throws -> [WorksiteMapMark]

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
        _ forceQueryDeltas: Bool,
        _ forceRefreshAll: Bool
    ) async throws

    func syncWorksitesFull(_ incidentId: Int64) async throws -> Bool

    func getWorksiteSyncStats(_ incidentId: Int64) throws -> IncidentDataSyncStats?

    func getLocalId(_ networkWorksiteId: Int64) throws -> Int64

    func syncNetworkWorksite(
        _ worksite: NetworkWorksiteFull,
        _ syncedAt: Date
    ) async throws -> Bool

    func pullWorkTypeRequests(_ networkWorksiteId: Int64) async throws

    func setRecentWorksite(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ viewStart: Date
    ) async throws

    func getUnsyncedCounts(_ worksiteId: Int64) throws -> [Int]

    func shareWorksite(
        worksiteId: Int64,
        emails: [String],
        phoneNumbers: [String],
        shareMessage: String,
        noClaimReason: String?
    ) async throws -> Bool
}

extension WorksitesRepository {
    func refreshWorksites(_ incidentId: Int64) async throws {
        try await refreshWorksites(incidentId, false, false)
    }

    func syncNetworkWorksite(_ worksite: NetworkWorksiteFull) async throws -> Bool {
        return try await syncNetworkWorksite(worksite, Date())
    }
}
