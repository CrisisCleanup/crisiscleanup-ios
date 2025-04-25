import Combine
import Foundation

protocol WorksitesSecondaryDataSyncer {
    var dataPullStats: any Publisher<IncidentDataPullStats, Never> { get }
    var onFullDataPullComplete: any Publisher<Int64, Never> { get }
    func sync(
        _ incidentId: Int64,
        _ secondarySyncStats: IncidentDataSyncStats?
    ) async throws
}

class IncidentWorksitesSecondaryDataSyncer: WorksitesSecondaryDataSyncer {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let networkDataCache: WorksitesNetworkDataCache
    private let worksiteDao: WorksiteDao
    private let worksiteSyncStatDao: WorksiteSyncStatDao
    private let appVersionProvider: AppVersionProvider
    private let logger: AppLogger

    private let dataPullStatsSubject = CurrentValueSubject<IncidentDataPullStats, Never>(IncidentDataPullStats())
    let dataPullStats: any Publisher<IncidentDataPullStats, Never>
    private let onFullDataPullCompleteSubject = CurrentValueSubject<Int64, Never>(0)
    let onFullDataPullComplete: any Publisher<Int64, Never>

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        networkDataCache: WorksitesNetworkDataCache,
        worksiteDao: WorksiteDao,
        worksiteSyncStatDao: WorksiteSyncStatDao,
        appVersionProvider: AppVersionProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.networkDataCache = networkDataCache
        self.worksiteDao = worksiteDao
        self.worksiteSyncStatDao = worksiteSyncStatDao
        self.appVersionProvider = appVersionProvider
        logger = loggerFactory.getLogger("incident-worksites-syncer")
        dataPullStats = dataPullStatsSubject
        onFullDataPullComplete = onFullDataPullCompleteSubject.share()
    }

    func networkWorksitesCount(_ incidentId: Int64, _ updatedAfter: Date?) async -> Int {
        0
    }

    private func getCleanSyncStats(_ incidentId: Int64) async -> IncidentDataSyncStats {
        let worksitesCount = await networkWorksitesCount(incidentId, nil)
        return IncidentDataSyncStats(
            incidentId: incidentId,
            syncStart: Date.now,
            dataCount: worksitesCount,
            pagedCount: 0,
            syncAttempt: SyncAttempt(successfulSeconds: 0, attemptedSeconds: 0, attemptedCounter: 0),
            appBuildVersionCode: appVersionProvider.buildNumber
        )
    }

    func sync(_ incidentId: Int64, _ secondarySyncStats: IncidentDataSyncStats?) async throws {
    }

//    private func saveSecondaryWorksitesData(
//        _ incidentId: Int64,
//        _ syncStats: IncidentDataSyncStats,
//        _ statsUpdater: IncidentDataPullStatsUpdater
//    ) async throws {
//        let isDeltaPull = syncStats.isDeltaPull
//        let updatedAfter: Date?
//        let syncCount: Int
//        if isDeltaPull {
//            updatedAfter = Date(timeIntervalSince1970: syncStats.syncAttempt.successfulSeconds)
//            syncCount = await networkWorksitesCount(incidentId, updatedAfter)
//        } else {
//            updatedAfter = nil
//            syncCount = syncStats.dataCount
//        }
//        if syncCount <= 0 {
//            return
//        }
//
//        statsUpdater.updateDataCount(syncCount)
//
//        statsUpdater.setPagingRequest()
//
//        var networkPullPage = 0
//        var requestingCount = 0
//        // TODO: Review if these page counts are optimal for secondary data
//        let pageCount = 5000
//        do {
//            while requestingCount < syncCount {
//                try await networkDataCache.saveWorksitesSecondaryData(
//                    incidentId: incidentId,
//                    pageCount: pageCount,
//                    pageIndex: networkPullPage,
//                    expectedCount: syncCount,
//                    updatedAfter: updatedAfter
//                )
//                networkPullPage += 1
//                requestingCount += pageCount
//
//                try Task.checkCancellation()
//
//                let requestedCount = min(requestingCount, syncCount)
//                statsUpdater.updateRequestedCount(requestedCount)
//            }
//        } catch {
//            if error is CancellationError {
//                throw error
//            }
//
//            logger.logError(error)
//        }
//
//        try await worksiteSyncStatDao.upsertSecondaryStats(syncStats.asSecondarySyncStatsRecord())
//
//        var startSyncRequestTime: Date?
//        var dbSaveCount = 0
//        var deleteCacheFiles = false
//        for dbSavePage in 0..<networkPullPage {
//            guard let cachedData = try networkDataCache.loadWorksitesSecondaryData(
//                incidentId: incidentId,
//                pageIndex: dbSavePage,
//                expectedCount: syncCount
//            ) else {
//                break
//            }
//
//            if startSyncRequestTime == nil {
//                startSyncRequestTime = cachedData.requestTime
//            }
//
//            // TODO: Deltas must account for deleted and/or reassigned if not inherently accounted for
//
//            let saveData = syncStats.pagedCount < dbSaveCount + pageCount || isDeltaPull
//            if saveData {
//                try await with(cachedData.secondaryData) {
//                    let worksitesIds = $0.map { w in w.id }
//                    let formData = $0.map {
//                        $0.formData.map { data in data.asWorksiteRecord() }
//                    }
//                    let reportedBys = $0.map { w in w.reportedBy }
//                    _ = try await saveToDb(
//                        worksiteIds: worksitesIds,
//                        formData: formData,
//                        reportedBys: reportedBys,
//                        statsUpdater: statsUpdater
//                    )
//                }
//            } else {
//                statsUpdater.addSavedCount(pageCount)
//            }
//
//            dbSaveCount += pageCount
//            let isSyncEnd = dbSaveCount >= syncCount
//
//            if saveData {
//                if isSyncEnd {
//                    try await worksiteSyncStatDao.updateSecondaryStatsSuccessful(
//                        incidentId,
//                        syncStats.syncStart,
//                        syncStats.dataCount,
//                        startSyncRequestTime,
//                        startSyncRequestTime,
//                        0,
//                        appVersionProvider.buildNumber
//                    )
//                } else if !isDeltaPull {
//                    try await worksiteSyncStatDao.updateSecondaryStatsPaged(
//                        incidentId,
//                        syncStats.syncStart,
//                        dbSaveCount
//                    )
//                }
//            }
//
//            if isSyncEnd {
//                deleteCacheFiles = true
//                break
//            }
//        }
//
//        if deleteCacheFiles {
//            for deleteCachePage in 0..<networkPullPage {
//                networkDataCache.deleteWorksitesSecondaryData(incidentId, deleteCachePage)
//            }
//        }
//    }
//
//    private func saveToDb(
//        worksiteIds: [Int64],
//        formData: [[WorksiteFormDataRecord]],
//        reportedBys: [Int64?],
//        statsUpdater: IncidentDataPullStatsUpdater
//    ) async throws -> Int {
//        var offset = 0
//        // TODO: Make configurable. Depends on the capabilities and/or OS version of the device as well.
//        let dbOperationLimit = 500
//        let limit = max(dbOperationLimit, 100)
//        var pagedCount = 0
//        while offset < worksiteIds.count {
//            let offsetEnd = min(offset + limit, worksiteIds.count)
//            let worksiteIdsSubset = Array(ArraySlice(worksiteIds[offset..<offsetEnd]))
//            let formDataSubset = Array(ArraySlice(formData[offset..<offsetEnd]))
//            let reportedBysSubset = Array(ArraySlice(reportedBys[offset..<offsetEnd]))
//            // Flags should have been saved by IncidentWorksitesSyncer
//            try await worksiteDao.syncAdditionalData(
//                worksiteIdsSubset,
//                formDataSubset,
//                reportedBysSubset
//            )
//
//            statsUpdater.addSavedCount(worksiteIdsSubset.count)
//
//            pagedCount += worksiteIdsSubset.count
//
//            offset += limit
//
//            try Task.checkCancellation()
//        }
//        return pagedCount
//    }
}
