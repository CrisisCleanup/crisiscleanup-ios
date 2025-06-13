import Atomics
import BackgroundTasks
import Combine
import UIKit

class AppSyncer: SyncPuller, SyncPusher {
    private let accountDataRepository: AccountDataRepository
    private let incidentCacheRepository: IncidentCacheRepository
    private let languageRepository: LanguageTranslationsRepository
    private let statusRepository: WorkTypeStatusRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let localImageRepository: LocalImageRepository
    private let appLogger: AppLogger
    private let syncLogger: SyncLogger

    private let incidentDataSyncNotifier: IncidentDataSyncNotifier

    private let accountData: AnyPublisher<AccountData, Never>
    private let appPreferences: AnyPublisher<AppPreferences, Never>

    private let pullTaskLock = NSRecursiveLock()
    private var pullTask: Task<SyncResult, Never>? = nil

    private let pullLanguageGuard = ManagedAtomic(false)

    private let syncMediaGuard = ManagedAtomic(false)

    private let syncWorksitesGuard = ManagedAtomic(false)

    init(
        accountDataRepository: AccountDataRepository,
        incidentCacheRepository: IncidentCacheRepository,
        languageRepository: LanguageTranslationsRepository,
        statusRepository: WorkTypeStatusRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        appPreferencesDataSource: AppPreferencesDataSource,
        localImageRepository: LocalImageRepository,
        incidentDataPullReporter: IncidentDataPullReporter,
        systemNotifier: SystemNotifier,
        translator: KeyTranslator,
        appLoggerFactory: AppLoggerFactory,
        syncLoggerFactory: SyncLoggerFactory,
    ) {
        self.accountDataRepository = accountDataRepository
        self.incidentCacheRepository = incidentCacheRepository
        self.languageRepository = languageRepository
        self.statusRepository = statusRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.localImageRepository = localImageRepository
        let logger = appLoggerFactory.getLogger("sync")
        appLogger = logger
        syncLogger = syncLoggerFactory.getLogger("app-syncer")

        incidentDataSyncNotifier = IncidentDataSyncNotifier(
            systemNotifier: systemNotifier,
            incidentDataPullReporter: incidentDataPullReporter,
            translator: translator,
            logger: logger,
        )

        accountData = accountDataRepository.accountData.eraseToAnyPublisher()
        appPreferences = appPreferencesDataSource.preferences.eraseToAnyPublisher()
    }

    private func validateAccountTokens() async throws -> SyncResult? {
        await accountDataRepository.updateAccountTokens()
        let hasValidTokens = try await accountData.asyncFirst().areTokensValid
        if !hasValidTokens {
            return .invalidAccountTokens
        }

        return nil
    }

    func appPullIncidentData(
        cancelOngoing: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheFullWorksites: Bool,
        restartCacheCheckpoint: Bool
    ) {
        Task {
            await syncPullIncidentData(
                cancelOngoing: cancelOngoing,
                forcePullIncidents: forcePullIncidents,
                cacheSelectedIncident: cacheSelectedIncident,
                cacheActiveIncidentWorksites: cacheActiveIncidentWorksites,
                cacheFullWorksites: cacheFullWorksites,
                restartCacheCheckpoint: restartCacheCheckpoint
            )
        }
    }

    func syncPullIncidentData(
        cancelOngoing: Bool,
        forcePullIncidents: Bool,
        cacheSelectedIncident: Bool,
        cacheActiveIncidentWorksites: Bool,
        cacheFullWorksites: Bool,
        restartCacheCheckpoint: Bool
    ) async -> SyncResult {
        do {
            if let invalidTokens = try await validateAccountTokens() {
                return invalidTokens
            }

            try Task.checkCancellation()

            let isPlanSubmitted = await incidentCacheRepository.submitPlan(
                overwriteExisting: cancelOngoing,
                forcePullIncidents: forcePullIncidents,
                cacheSelectedIncident: cacheSelectedIncident,
                cacheActiveIncidentWorksites: cacheActiveIncidentWorksites,
                cacheWorksitesAdditional: cacheFullWorksites,
                restartCacheCheckpoint: restartCacheCheckpoint
            )
            if !isPlanSubmitted {
                return .notAttempted(reason: "Sync is redundant or unnecessary")
            }

            let syncTask = Task {
                do {
                    return try await incidentDataSyncNotifier.notifySync {
                        try await self.incidentCacheRepository.sync()
                    }
                } catch {
                    appLogger.logError(error)
                    return .error(message: error.localizedDescription)
                }
            }

            pullTaskLock.withLock {
                stopPullWorksites()

                pullTask = syncTask
            }

            return await syncTask.result.get()
        } catch is CancellationError {
            return .canceled
        } catch {
            appLogger.logError(error)
            return .error(message: error.localizedDescription)
        }
    }

    func stopPullWorksites() {
        pullTaskLock.withLock {
            pullTask?.cancel()
        }
    }

    func pullUnauthenticatedData() {
        Task {
            await withThrowingTaskGroup(of: Void.self) { group -> Void in
                group.addTask { await self.pullLanguage() }
                group.addTask { await self.pullStatuses() }
                do {
                    try await group.waitForAll()
                } catch {
                    appLogger.logError(error)
                }
            }
        }
    }

    private func pullLanguage() async {
        if pullLanguageGuard.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged {
            defer { pullLanguageGuard.store(false, ordering: .relaxed) }

            await languageRepository.loadLanguages()
        }
    }

    private func pullStatuses() async {
        await statusRepository.loadStatuses()
    }

    // MARK: SyncPusher

    func appPushWorksite(_ worksiteId: Int64, _ scheduleMediaSync: Bool) {
        Task {
            do {
                if let _ = try await self.validateAccountTokens() {
                    return
                }

                try Task.checkCancellation()

                let isSyncAttempted = await self.worksiteChangeRepository.trySyncWorksite(worksiteId)
                if isSyncAttempted {
                    await self.worksiteChangeRepository.syncUnattemptedWorksite(worksiteId)

                    if scheduleMediaSync {
                        self.scheduleSyncMedia()
                    }
                }
            } catch {
                self.appLogger.logError(error)
            }
        }
    }

    func syncMedia() async -> Bool {
        guard !self.syncMediaGuard.exchange(true, ordering: .sequentiallyConsistent) else {
            return false
        }

        do {
            defer {
                self.syncMediaGuard.store(false, ordering: .sequentiallyConsistent)
            }

            let isSyncedAll = try await worksiteChangeRepository.syncWorksiteMedia()
            return isSyncedAll
        } catch {
            appLogger.logError(error)
        }

        return false
    }

    private func runInBackground(
        taskName: String,
        action: @escaping () async -> Void,
    ) {
        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: taskName)

        guard backgroundTaskId != .invalid else {
            return
        }

        Task {
            let application = await UIApplication.shared
            do {
                defer {
                    application.endBackgroundTask(backgroundTaskId)
                }

                await action()
            }
        }
    }

    func scheduleSyncMedia() {
        runInBackground(taskName: "app-upload-media") {
            let _ = await self.syncMedia()
        }
    }

    func syncWorksites() async {
        guard !self.syncWorksitesGuard.exchange(true, ordering: .sequentiallyConsistent) else {
            return
        }

        do {
            defer {
                self.syncWorksitesGuard.store(false, ordering: .sequentiallyConsistent)
            }

            await worksiteChangeRepository.syncWorksites()
        }
    }

    private func syncWorksitesAndMedia() async {
        await syncWorksites()
        _ = await syncMedia()
    }

    func scheduleSyncWorksites() {
        runInBackground(taskName: "app-upload-worksites") {
            await self.syncWorksitesAndMedia()
        }
    }
}
