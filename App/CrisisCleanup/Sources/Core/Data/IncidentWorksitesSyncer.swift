import Combine
import Foundation

protocol WorksitesSyncer {
    var dataPullStats: any Publisher<IncidentDataPullStats, Never> { get }

    func networkWorksitesCount(
        _ incidentId: Int64,
        _ updatedAfter: Date?
    ) async -> Int

    func sync(
        _ incidentId: Int64,
        _ syncStats: IncidentDataSyncStats
    ) async throws
}

extension WorksitesSyncer {
    func networkWorksitesCount(_ incidentId: Int64) async -> Int {
        await networkWorksitesCount(incidentId, nil)
    }
}

// TODO Test coverage

class IncidentWorksitesSyncer: WorksitesSyncer {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let networkDataCache: WorksitesNetworkDataCache
    private let worksiteDao: WorksiteDao
    private let worksiteSyncStatDao: WorksiteSyncStatDao
    private let appVersionProvider: AppVersionProvider
    private let logger: AppLogger

    private let dataPullStatsSubject = CurrentValueSubject<IncidentDataPullStats, Never>(IncidentDataPullStats())
    let dataPullStats: any Publisher<IncidentDataPullStats, Never>

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
        logger = loggerFactory.getLogger("worksites-sync")
        dataPullStats = dataPullStatsSubject
    }

    func networkWorksitesCount(_ incidentId: Int64, _ updatedAfter: Date?) async -> Int {
        do {
            return try await networkDataSource.getWorksitesCount(incidentId, updatedAfter)
        } catch {
            logger.logError(error)
            return 0
        }
    }

    func sync(
        _ incidentId: Int64,
        _ syncStats: IncidentDataSyncStats
    ) async throws {
        let statsUpdater = IncidentDataPullStatsUpdater(
            { stats in self.dataPullStatsSubject.value = stats }
        )
        statsUpdater.beginPull(incidentId)
        do {
            defer { statsUpdater.endPull() }
            try await saveWorksitesData(incidentId, syncStats, statsUpdater)
        }
    }

    private func saveWorksitesData(
        _ incidentId: Int64,
        _ syncStats: IncidentDataSyncStats,
        _ statsUpdater: IncidentDataPullStatsUpdater
    ) async throws {
        let isDeltaPull = syncStats.isDeltaPull
        let updatedAfter: Date?
        let syncCount: Int
        if isDeltaPull {
            updatedAfter = Date(timeIntervalSince1970: syncStats.syncAttempt.successfulSeconds)
            syncCount = await networkWorksitesCount(incidentId, updatedAfter)
        } else {
            updatedAfter = nil
            syncCount = syncStats.dataCount
        }
        if syncCount <= 0 {
            return
        }

        statsUpdater.updateDataCount(syncCount)

        statsUpdater.setPagingRequest()

        var networkPullPage = 0
        var requestingCount = 0
        let pageCount = 5000
        do {
            while (requestingCount < syncCount) {
                try await networkDataCache.saveWorksitesShort(
                    incidentId: incidentId,
                    pageCount: pageCount,
                    pageIndex: networkPullPage,
                    expectedCount: syncCount,
                    updatedAfter: updatedAfter
                )
                networkPullPage += 1
                requestingCount += pageCount

                try Task.checkCancellation()

                let requestedCount = min(requestingCount, syncCount)
                statsUpdater.updateRequestedCount(requestedCount)
            }
        } catch {
            if error is CancellationError {
                throw error
            }

            logger.logError(error)
        }

        var startSyncRequestTime: Date? = nil
        var dbSaveCount = 0
        var deleteCacheFiles = false
        for dbSavePage in 0..<networkPullPage {
            guard let cachedData = try networkDataCache.loadWorksitesShort(
                incidentId,
                dbSavePage,
                syncCount
            ) else {
                break
            }

            if startSyncRequestTime == nil {
                startSyncRequestTime = cachedData.requestTime
            }

            // TODO Deltas must account for deleted and/or reassigned if not inherently accounted for

            let saveData = syncStats.pagedCount < dbSaveCount + pageCount || isDeltaPull
            if saveData {
                try await with(cachedData.worksites) {
                    let worksites = $0.map { w in w.asRecord() }
                    let flags = $0.map {
                        $0.flags
                            .filter { flag in flag.invalidatedAt == nil }
                            .map { f in f.asRecord() }
                    }
                    let workTypes = $0.map { wt in
                        wt.newestWorkTypes()
                            .map { n in n.asRecord() }
                    }
                    _ = try await saveToDb(
                        worksites,
                        flags,
                        workTypes,
                        cachedData.requestTime,
                        statsUpdater
                    )
                }
            } else {
                statsUpdater.addSavedCount(pageCount)
            }

            dbSaveCount += pageCount
            let isSyncEnd = dbSaveCount >= syncCount

            if saveData {
                if isSyncEnd {
                    try await worksiteSyncStatDao.updateStatsSuccessful(
                        incidentId,
                        syncStats.syncStart,
                        syncStats.dataCount,
                        startSyncRequestTime,
                        startSyncRequestTime,
                        0,
                        appVersionProvider.buildNumber
                    )
                } else if !isDeltaPull {
                    try await worksiteSyncStatDao.updateStatsPaged(
                        incidentId,
                        syncStats.syncStart,
                        dbSaveCount
                    )
                }
            }

            if isSyncEnd {
                deleteCacheFiles = true
                break
            }
        }

        if deleteCacheFiles {
            for deleteCachePage in 0..<networkPullPage {
                await networkDataCache.deleteWorksitesShort(incidentId, deleteCachePage)
            }
        }
    }

    private func saveToDb(
        _ worksites: [WorksiteRecord],
        _ flags: [[WorksiteFlagRecord]],
        _ workTypes: [[WorkTypeRecord]],
        _ syncStart: Date,
        _ statsUpdater: IncidentDataPullStatsUpdater
    ) async throws -> Int {
        var offset = 0
        // TODO Make configurable. Depends on the capabilities and/or OS version of the device as well.
        let dbOperationLimit = 500
        let limit = max(dbOperationLimit, 100)
        var pagedCount = 0
        while (offset < worksites.count) {
            let offsetEnd = min((offset + limit), worksites.count)
            let worksiteSubset = Array(ArraySlice(worksites[offset..<offsetEnd]))
            let workTypeSubset = Array(ArraySlice(workTypes[offset..<offsetEnd]))
            try await worksiteDao.syncWorksites(
                worksiteSubset,
                workTypeSubset,
                syncStart
            )

            let flagSubset = ArraySlice(flags[offset..<offsetEnd])
            try await worksiteDao.syncShortFlags(
                worksiteSubset,
                Array(flagSubset)
            )

            statsUpdater.addSavedCount(worksiteSubset.count)

            pagedCount += worksiteSubset.count

            offset += limit

            try Task.checkCancellation()
        }
        return pagedCount
    }
}
