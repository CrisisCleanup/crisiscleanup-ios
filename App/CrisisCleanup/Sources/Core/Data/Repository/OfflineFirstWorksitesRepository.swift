import Combine
import Foundation

class OfflineFirstWorksitesRepository: WorksitesRepository {
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    var isLoading: any Publisher<Bool, Never>

    private let syncWorksitesFullIncidentIdSubject = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    var syncWorksitesFullIncidentId: any Publisher<Int64, Never>

    init(
    ) {
        self.isLoading = isLoadingSubject
        self.syncWorksitesFullIncidentId = syncWorksitesFullIncidentIdSubject
    }

    func streamWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeLeft: Double,
        longitudeRight: Double,
        limit: Int,
        offset: Int) async -> any Publisher<[WorksiteMapMark], Error> {
            // TODO: Do
            return PassthroughSubject<[WorksiteMapMark], Error>()
        }

    func streamWorksites(
        _ incidentId: Int64,
        _ limit: Int,
        _ offset: Int
    ) -> any Publisher<[Worksite], Error> {
        // TODO: Do
        return PassthroughSubject<[Worksite], Error>()
    }

    func streamIncidentWorksitesCount(_ id: Int64) -> any Publisher<Int, Never> {
        // TODO: Do
        return PassthroughSubject<Int, Never>()
    }

    func streamLocalWorksite(_ worksiteId: Int64) -> any Publisher<LocalWorksite?, Never> {
        // TODO: Do
        return PassthroughSubject<LocalWorksite?, Never>()
    }

    func streamRecentWorksites(_ incidentId: Int64) -> any Publisher<[WorksiteSummary], Never> {
        // TODO: Do
        return PassthroughSubject<[WorksiteSummary], Never>()
    }

    func getWorksitesMapVisual(_ incidentId: Int64, _ limit: Int, _ offset: Int) throws -> [WorksiteMapMark] {
        // TODO: Do
        return []
    }

    func getWorksitesMapVisual(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeWest: Double,
        longitudeEast: Double,
        limit: Int,
        offset: Int) async throws -> [WorksiteMapMark] {
            // TODO: Do
            return []
        }

    func getWorksitesCount(_ incidentId: Int64) throws -> Int {
        // TODO: Do
        return 0
    }

    func getWorksitesCount(
        incidentId: Int64,
        latitudeSouth: Double,
        latitudeNorth: Double,
        longitudeLeft: Double,
        longitudeRight: Double) -> Int {
            // TODO: Do
            return 0
        }

    func refreshWorksites(
        _ incidentId: Int64,
        _ forceQueryDeltas: Bool,
        _ forceRefreshAll: Bool
    ) async throws {
        // TODO: Do
    }

    func syncWorksitesFull(_ incidentId: Int64) async throws -> Bool {
        // TODO: Do
        return false
    }

    func getWorksiteSyncStats(_ incidentId: Int64) throws -> IncidentDataSyncStats? {
        // TODO: Do
        return nil
    }
    func syncNetworkWorksite(_ worksite: NetworkWorksiteFull, _ syncedAt: Date) async throws -> Bool {
        // TODO: Do
        return false
    }

    func getLocalId(_ networkWorksiteId: Int64) throws -> Int64 {
        // TODO: Do
        return 0
    }

    func pullWorkTypeRequests(_ networkWorksiteId: Int64) async throws {
        // TODO: Do
    }

    func setRecentWorksite(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ viewStart: Date) async throws {
            // TODO: Do
        }

    func getUnsyncedCounts(_ worksiteId: Int64) throws -> [Int] {
        // TODO: Do
        return []
    }

    func shareWorksite(
        worksiteId: Int64,
        emails: [String],
        phoneNumbers: [String],
        shareMessage: String,
        noClaimReason: String?) async throws -> Bool {
            // TODO: Do
            return false
        }
}
