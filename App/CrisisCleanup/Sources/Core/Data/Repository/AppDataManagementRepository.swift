import Foundation

public protocol AppDataManagementRepository {
    // TODO: Rebuild FTS

    func clearAppData()
}

class CrisisCleanupDataManagementRepository: AppDataManagementRepository {
    private let incidentsRepository: IncidentsRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let worksiteSyncStatDao: WorksiteSyncStatDao
    private let syncPuller: SyncPuller
    private let databaseOperator: DatabaseOperator
    private let accountEventBus: AccountEventBus
    private let logger: AppLogger

    private let clearDataLock = NSLock()
    private var isClearingAppData = false

    private let oneSecondNs = 1_000_000_000

    init(
        incidentsRepository: IncidentsRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        worksiteSyncStatDao: WorksiteSyncStatDao,
        syncPuller: SyncPuller,
        databaseOperator: DatabaseOperator,
        accountEventBus: AccountEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.worksiteSyncStatDao = worksiteSyncStatDao
        self.syncPuller = syncPuller
        self.databaseOperator = databaseOperator
        self.accountEventBus = accountEventBus
        logger = loggerFactory.getLogger("app-data")
    }

    func clearAppData() {
        let isOpenToClear = clearDataLock.withLock {
            if isClearingAppData {
                return false
            }

            isClearingAppData = true
            return true
        }

        if isOpenToClear {
            Task {
                do {
                    defer {
                        isClearingAppData = false
                    }

                    if incidentsRepository.incidentCount == 0 {
                        return
                    }

                    Task {
                        stopSyncPull()
                    }

                    try await Task.sleep(nanoseconds: (UInt64)(5 * oneSecondNs))

                    for _ in 0..<3 {
                        try databaseOperator.clearBackendDataTables()

                        if isAppDataCleared() {
                            break
                        }

                        try await Task.sleep(nanoseconds: (UInt64)(2 * oneSecondNs))
                    }

                    try await Task.sleep(nanoseconds: (UInt64)(3 * oneSecondNs))

                    try Task.checkCancellation()

                    if !isAppDataCleared() {
                        logger.logCapture("Unable to clear app data")
                        return
                    }

                    accountEventBus.onLogout()
                } catch {
                    logger.logError(error)
                }
            }
        }
    }

    private func stopSyncPull() {
        syncPuller.stopPullIncident()
        syncPuller.stopPull()
    }

    private func isAppDataCleared() -> Bool {
        incidentsRepository.incidentCount == 0 &&
        worksiteChangeRepository.worksiteChangeCount == 0 &&
        worksiteSyncStatDao.getWorksiteSyncStatCount() == 0
    }
}
