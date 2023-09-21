import Foundation

// !App build numbers may differ on prod and non-prod!

/**
 * Build version of the app where worksite (related) entity models were last changed
 */
private let WorksitesStableModelBuildVersion = 56

/**
 * Build version of the app where incident organization (related) entity models were last changed
 */
let IncidentOrganizationsStableModelBuildVersion = 40

/**
 * Keeps track of incident data (worksites, organizations, ...) syncing
 */
public struct IncidentDataSyncStats {
    let incidentId: Int64
    /**
     * Timestamp when the incident first started syncing
     *
     * See [syncAttempt] for last successful sync timestamp
     */
    let syncStart: Date
    /**
     * Number of (worksites, organizations, ...) reported on first sync
     */
    let dataCount: Int
    /**
     * Number of data (pages) pulled and saved locally during first sync
     *
     * This is the same units as [dataCount].
     */
    let pagedCount: Int
    /**
     * Sync attempt stats after the first full sync (of base data)
     */
    let syncAttempt: SyncAttempt

    let appBuildVersionCode: Int64

    /**
     * App build version where the network data model was last changed
     */
    private let stableModelVersion: Int

    // sourcery:begin: skipCopy
    /**
     * TRUE if the underlying worksite model has changed since the incident was last synced
     */
    var isDataVersionOutdated: Bool { appBuildVersionCode < stableModelVersion }

    private var isInitialPull: Bool { pagedCount < dataCount }

    var shouldSync: Bool {
        isInitialPull ||
        isDataVersionOutdated ||
        syncAttempt.shouldSyncPassively(recentIntervalSeconds: 600)
    }

    var isDeltaPull: Bool { !isInitialPull }
    // sourcery:end

    init(
        incidentId: Int64,
        syncStart: Date,
        dataCount: Int,
        pagedCount: Int = 0,
        syncAttempt: SyncAttempt,
        appBuildVersionCode: Int64,
        stableModelVersion: Int = WorksitesStableModelBuildVersion
    ) {
        self.incidentId = incidentId
        self.syncStart = syncStart
        self.dataCount = dataCount
        self.pagedCount = pagedCount
        self.syncAttempt = syncAttempt
        self.appBuildVersionCode = appBuildVersionCode
        self.stableModelVersion = stableModelVersion
    }
}
