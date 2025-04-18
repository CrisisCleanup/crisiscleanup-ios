import Combine
import Foundation

public protocol IncidentCacheRepository {
    var isSyncingActiveIncident: any Publisher<Bool, Never> { get }
    var cacheStage: any Publisher<IncidentCacheStage, Never> { get }

    var cachePreferences: any Publisher<IncidentWorksitesCachePreferences, Never> { get }

    func streamSyncStats(_ incidentId: Int64) -> any Publisher<IncidentDataSyncParameters?, Never>

    /**
     *  Returns: TRUE when plan is accepted or FALSE otherwise (already queued or unable to cancel ongoing)
     */
    func submitPlan(
        overwriteExisting: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheWorksitesAdditional: Bool,
        restartCacheCheckpoint: Bool,
        planTimeout: TimeInterval,
    ) async -> Bool

    func sync() async -> SyncResult

    func resetIncidentSyncStats(_ incidentId: Int64) async -> Int64

    func updateCachePreferenes(_ preferences: IncidentWorksitesCachePreferences) async
}

extension IncidentCacheRepository {
    func submitPlan(
        overwriteExisting: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheWorksitesAdditional: Bool,
        restartCacheCheckpoint: Bool
    ) async -> Bool {
        await submitPlan(
            overwriteExisting: overwriteExisting,
            forcePullIncidents: forcePullIncidents,
            cacheSelectedIncident: cacheSelectedIncident,
            cacheActiveIncidentWorksites: cacheActiveIncidentWorksites,
            cacheWorksitesAdditional: cacheWorksitesAdditional,
            restartCacheCheckpoint: restartCacheCheckpoint,
            planTimeout: 9.seconds
        )
    }
}

public enum IncidentCacheStage: String, Identifiable, CaseIterable {
    case start,
         incidents,
         worksitesBounded,
         worksitesPreload,
         worksitesCore,
         worksitesAdditional,
         activeIncident,
         activeIncidentOrganization,
         end

    public var id: String { rawValue }
}

private struct IncidentDataSyncPlan {
    // May be a new Incident ID
    let incidentId: Int64
    let syncIncidents: Bool
    let syncSelectedIncident: Bool
    let syncActiveIncidentWorksites: Bool
    let syncWorksitesAdditional: Bool
    let restartCache: Bool
    let timestamp: Date

    init(
        incidentId: Int64,
        syncIncidents: Bool,
        syncSelectedIncident: Bool,
        syncActiveIncidentWorksites: Bool,
        syncWorksitesAdditional: Bool,
        restartCache: Bool,
        timestamp: Date = Date.now
    ) {
        self.incidentId = incidentId
        self.syncIncidents = syncIncidents
        self.syncSelectedIncident = syncSelectedIncident
        self.syncActiveIncidentWorksites = syncActiveIncidentWorksites
        self.syncWorksitesAdditional = syncWorksitesAdditional
        self.restartCache = restartCache
        self.timestamp = timestamp
    }

    private lazy var syncSelectedIncidentLevel: Int = {
        if (syncSelectedIncident) {
            1
        } else {
            0
        }
    }()

    private lazy var syncWorksitesLevel: Int = {
        if (syncWorksitesAdditional) {
            2
        } else if (syncActiveIncidentWorksites) {
            1
        } else {
            0
        }
    }()
}

private let EmptySyncPlan = IncidentDataSyncPlan(
    incidentId: EmptyIncident.id,
    syncIncidents: false,
    syncSelectedIncident: false,
    syncActiveIncidentWorksites: false,
    syncWorksitesAdditional: false,
    restartCache: false,
)

extension Array where Element == Double {
    fileprivate func radiusMiles(boundedRegion: IncidentDataSyncParameters.BoundedRegion) -> Double? {
        return count == 2
        ? haversineDistance(
            get(1, 0.0).radians,
            get(0, 0.0).radians,
            boundedRegion.latitude.radians,
            boundedRegion.longitude.radians,
        ).kmToMiles
        : nil
    }
}
