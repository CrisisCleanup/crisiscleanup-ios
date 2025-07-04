import Foundation

public protocol AppDataManagementRepository {
    // TODO: Rebuild FTS

    func clearAppData()
    func backgroundClearAppData(_ refreshBackendData: Bool) async -> Bool
}

class CrisisCleanupDataManagementRepository: AppDataManagementRepository {
    private let incidentsRepository: IncidentsRepository
    private let accountDataRepository: AccountDataRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let incidentDataSyncParameterDao: IncidentDataSyncParameterDao
    private let incidentCacheRepository: IncidentCacheRepository
    private let languageTranslationsRepository: LanguageTranslationsRepository
    private let workTypeStatusRepository: WorkTypeStatusRepository
    private let casesFilterRepository: CasesFilterRepository
    private let appSupportRepository: AppSupportRepository
    private let syncPuller: SyncPuller
    private let databaseOperator: DatabaseOperator
    private let accountEventBus: AccountEventBus
    private let logger: AppLogger

    private let clearDataLock = NSLock()
    private var isClearingAppData = false

    private let oneSecondNs = UInt64(1_000_000_000)

    init(
        incidentsRepository: IncidentsRepository,
        accountDataRepository: AccountDataRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        incidentDataSyncParameterDao: IncidentDataSyncParameterDao,
        incidentCacheRepository: IncidentCacheRepository,
        languageTranslationsRepository: LanguageTranslationsRepository,
        workTypeStatusRepository: WorkTypeStatusRepository,
        casesFilterRepository: CasesFilterRepository,
        appSupportRepository: AppSupportRepository,
        syncPuller: SyncPuller,
        databaseOperator: DatabaseOperator,
        accountEventBus: AccountEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.accountDataRepository = accountDataRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.incidentDataSyncParameterDao = incidentDataSyncParameterDao
        self.incidentCacheRepository = incidentCacheRepository
        self.languageTranslationsRepository = languageTranslationsRepository
        self.workTypeStatusRepository = workTypeStatusRepository
        self.casesFilterRepository = casesFilterRepository
        self.appSupportRepository = appSupportRepository
        self.syncPuller = syncPuller
        self.databaseOperator = databaseOperator
        self.accountEventBus = accountEventBus
        logger = loggerFactory.getLogger("app-data")
    }

    func clearAppData() {
        Task {
            let _ = await backgroundClearAppData(true)
        }
    }
    func backgroundClearAppData(_ refreshBackendData: Bool) async -> Bool {
        let isOpenToClear = clearDataLock.withLock {
            if isClearingAppData {
                return false
            }

            isClearingAppData = true
            return true
        }
        if !isOpenToClear {
            return false
        }

        do {
            defer {
                clearDataLock.withLock {
                    isClearingAppData = false
                }
            }

            if incidentsRepository.incidentCount == 0 {
                return true
            }

            accountDataRepository.clearAccountTokens()

            stopSyncPull()
            for _ in 0..<19 {
                try await Task.sleep(nanoseconds: 3 * oneSecondNs)
                if try await isSyncPullStopped() {
                    break
                }
            }


            for _ in 0..<6 {
                try await clearPersistedAppData()

                try await Task.sleep(nanoseconds: oneSecondNs)
                if isPersistedAppDataCleared() {
                    break
                }
            }

            try await Task.sleep(nanoseconds: 3 * oneSecondNs)

            try Task.checkCancellation()

            if !isPersistedAppDataCleared() {
                logger.logCapture("Unable to clear app data")
                return false
            }

            accountEventBus.onLogout()

            if refreshBackendData {
                await languageTranslationsRepository.loadLanguages(true)
                await workTypeStatusRepository.loadStatuses(true)
            }

            return true
        } catch {
            logger.logError(error)
            return false
        }
    }

    private func stopSyncPull() {
        syncPuller.stopPullWorksites()
    }

    private func isSyncPullStopped() async throws -> Bool {
        let cacheStage = try await incidentCacheRepository.cacheStage.eraseToAnyPublisher().asyncFirst()
        return !cacheStage.isSyncingStage
    }

    private func clearPersistedAppData() async throws {
        try databaseOperator.clearBackendDataTables()
        casesFilterRepository.changeFilters(CasesFilter())
        incidentCacheRepository.updateCachePreferences(InitialIncidentWorksitesCachePreferences)
        appSupportRepository.onAppOpen()
    }

    private func isPersistedAppDataCleared() -> Bool {
        incidentsRepository.incidentCount == 0 &&
        worksiteChangeRepository.worksiteChangeCount == 0 &&
        incidentDataSyncParameterDao.getSyncStatCount() == 0
    }
}
