import Foundation

public protocol AppDataManagementRepository {
    // TODO: Rebuild FTS

    func clearAppData()
}

class CrisisCleanupDataManagementRepository: AppDataManagementRepository {
    private let incidentsRepository: IncidentsRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let incidentDataSyncParameterDao: IncidentDataSyncParameterDao
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
        incidentDataSyncParameterDao: IncidentDataSyncParameterDao,
        syncPuller: SyncPuller,
        databaseOperator: DatabaseOperator,
        accountEventBus: AccountEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.incidentDataSyncParameterDao = incidentDataSyncParameterDao
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

                        if isPersistedAppDataCleared() {
                            break
                        }

                        try await Task.sleep(nanoseconds: (UInt64)(2 * oneSecondNs))
                    }

                    try await Task.sleep(nanoseconds: (UInt64)(3 * oneSecondNs))

                    try Task.checkCancellation()

                    if !isPersistedAppDataCleared() {
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
        syncPuller.stopPullWorksites()
    }

    private func isPersistedAppDataCleared() -> Bool {
        incidentsRepository.incidentCount == 0 &&
        worksiteChangeRepository.worksiteChangeCount == 0 &&
        incidentDataSyncParameterDao.getSyncStatCount() == 0
    }
}
