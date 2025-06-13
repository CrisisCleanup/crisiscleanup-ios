
public protocol SyncPuller {
    func appPullIncidentData(
        cancelOngoing: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheFullWorksites: Bool,
        restartCacheCheckpoint: Bool
    )

    func syncPullIncidentData(
        cancelOngoing: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheFullWorksites: Bool,
        restartCacheCheckpoint: Bool
    ) async -> SyncResult

    func stopPullWorksites()

    func pullUnauthenticatedData()
}

extension SyncPuller {
    func appPullIncidentData(cancelOngoing: Bool) {
        appPullIncidentData(
            cancelOngoing: cancelOngoing,
            forcePullIncidents: false,
            cacheSelectedIncident: false,
            cacheActiveIncidentWorksites: true,
            cacheFullWorksites: false,
            restartCacheCheckpoint: false
        )
    }

    func appPullIncidents() {
        appPullIncidentData(
            cancelOngoing: true,
            forcePullIncidents: true,
            cacheSelectedIncident: true,
            cacheActiveIncidentWorksites: false,
            cacheFullWorksites: false,
            restartCacheCheckpoint: false
        )
    }

    func syncPullIncidents() async -> SyncResult {
        await syncPullIncidentData(
            cancelOngoing: true,
            forcePullIncidents: true,
            cacheSelectedIncident: true,
            cacheActiveIncidentWorksites: false,
            cacheFullWorksites: false,
            restartCacheCheckpoint: false
        )
    }
}

public enum SyncResult {
    case notAttempted(reason: String),
         success(notes: String),
         partial(notes: String),
         error(message: String),
         canceled,
         invalidAccountTokens
}

public protocol SyncPusher {
    func appPushWorksite(_ worksiteId: Int64, _ scheduleMediaSync: Bool)

    func scheduleSyncMedia()
    func scheduleSyncWorksites()

    func syncMedia() async -> Bool
    func syncWorksites() async
}

extension SyncPusher {
    func appPushWorksite(_ worksiteId: Int64) {
        appPushWorksite(worksiteId, false)
    }
}
