import Combine
import Foundation

public protocol WorksitesRepository {
    var isLoading: Published<Bool>.Publisher { get }

    var syncWorksitesFullIncidentId: Published<[Int64]>.Publisher { get }

    func streamWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        Int64itudeLeft: Double,
        Int64itudeRight: Double,
        limit: Int,
        offset: Int
    ) async throws -> Published<[[WorksiteMapMark]]>.Publisher

    /**
     * Stream of an incident's [Worksite]s
     */
    func streamWorksites(incidentId: Int64, limit: Int, offset: Int) throws -> Published<[Worksite]>.Publisher

    func streamIncidentWorksitesCount(id: Int64) throws -> Published<Int>.Publisher

    func streamLocalWorksite(_ worksiteId: Int64) throws -> Published<LocalWorksite?>.Publisher

    func streamRecentWorksites(_ incidentId: Int64) throws -> Published<[[WorksiteSummary]]>.Publisher

    func getWorksitesMapVisual(incidentId: Int64, limit: Int, offset: Int) throws -> [WorksiteMapMark]

    func getWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        Int64itudeWest: Double,
        Int64itudeEast: Double,
        limit: Int,
        offset: Int
    ) throws -> [WorksiteMapMark]

    func getWorksitesCount(incidentId: Int64) throws -> Int

    func getWorksitesCount(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        Int64itudeLeft: Double,
        Int64itudeRight: Double
    ) throws -> Int

    func refreshWorksites(
        _ incidentId: Int64,
        _ forceQueryDeltas: Bool,
        _ forceRefreshAll: Bool
    ) async throws

    func syncWorksitesFull(incidentId: Int64) async throws -> Bool

    func getWorksiteSyncStats(incidentId: Int64) throws -> IncidentDataSyncStats?

    func getLocalId(networkWorksiteId: Int64) throws -> Int64

    func syncNetworkWorksite(
        _ worksite: NetworkWorksiteFull,
        _ syncedAt: Date
    ) async throws -> Bool

    func pullWorkTypeRequests(networkWorksiteId: Int64) async throws

    func setRecentWorksite(
        incidentId: Int64,
        worksiteId: Int64,
        viewStart: Date
    ) async throws

    func getUnsyncedCounts(worksiteId: Int64) throws -> [Int]

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
