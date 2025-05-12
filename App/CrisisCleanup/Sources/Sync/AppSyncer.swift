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

    private let accountData: AnyPublisher<AccountData, Never>
    private let appPreferences: AnyPublisher<AppPreferences, Never>

    // TODO: IncidentDataSyncNotifier (uses IncidentDataPullReporter)

    private let pullTaskLock = NSRecursiveLock()
    private var pullTask: Task<SyncResult, Never>? = nil

    private let pullLanguageGuard = ManagedAtomic(false)

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentCacheRepository: IncidentCacheRepository,
        languageRepository: LanguageTranslationsRepository,
        statusRepository: WorkTypeStatusRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        appPreferencesDataSource: AppPreferencesDataSource,
        localImageRepository: LocalImageRepository,
        appLoggerFactory: AppLoggerFactory,
        syncLoggerFactory: SyncLoggerFactory,
    ) {
        self.accountDataRepository = accountDataRepository
        self.incidentCacheRepository = incidentCacheRepository
        self.languageRepository = languageRepository
        self.statusRepository = statusRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.localImageRepository = localImageRepository
        appLogger = appLoggerFactory.getLogger("sync")
        syncLogger = syncLoggerFactory.getLogger("app-syncer")

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
                    // TODO: Notify sync
                    // TODO: Manage background syncing
                    return try await incidentCacheRepository.sync()
                } catch {
                    appLogger.logError(error)
                    return SyncResult.error(message: error.localizedDescription)
                }
            }

            pullTaskLock.withLock {
                if cancelOngoing {
                    pullTask?.cancel()
                }

                pullTask = syncTask
            }

            return await syncTask.result.get()
        } catch {
            appLogger.logError(error)

            // TODO: Take additional action as necessary

            return SyncResult.error(message: error.localizedDescription)
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
        // TODO: Run sync in background task (if not running to completion)
        Task {
            do {
                if let _ = try await validateAccountTokens() {
                    return
                }

                try Task.checkCancellation()

                let isSyncAttempted = await worksiteChangeRepository.trySyncWorksite(worksiteId)
                if isSyncAttempted {
                    await worksiteChangeRepository.syncUnattemptedWorksite(worksiteId)

                    if scheduleMediaSync {
                        scheduleSyncMedia()
                    }
                }

            } catch {
                // TODO: Handle proper
                print(error)
            }
        }
    }

    func syncPushWorksitesAsync() async {
        Task {
            do {
                if let _ = try await validateAccountTokens() {
                    return
                }

                try Task.checkCancellation()

                _ = await worksiteChangeRepository.syncWorksites()
            } catch {
                // TODO: Handle proper
                print(error)
            }
        }
    }

    // TODO: Move both background tasks below into BackgroundTaskCoordinator and apply better pattern

    private let syncMediaGuard = ManagedAtomic(false)
    func scheduleSyncMedia() {
        var syncingTask: Task<Void, Error>? = nil

        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "sync-media") {
            syncingTask?.cancel()
            UIApplication.shared.endBackgroundTask(bgTaskId)
        }

        let bgTaskIdConst = bgTaskId
        syncingTask = Task {
            do {
                defer {
                    self.syncMediaGuard.store(false, ordering: .sequentiallyConsistent)

                    Task { @MainActor in
                        UIApplication.shared.endBackgroundTask(bgTaskIdConst)
                    }
                }

                if self.syncMediaGuard.exchange(true, ordering: .sequentiallyConsistent) {
                    return
                }

                let isSyncAll = try await worksiteChangeRepository.syncWorksiteMedia()
                if !isSyncAll {
                    // TODO: Schedule delayed background sync
                }
            } catch {
                // TODO: Handle proper. Could be cancellation.
                print("Sync media error \(error)")
            }
        }
    }

    private let syncWorksitesGuard = ManagedAtomic(false)
    func scheduleSyncWorksites() {
        var syncingTask: Task<Void, Error>? = nil

        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "sync-worksites") {
            syncingTask?.cancel()
            UIApplication.shared.endBackgroundTask(bgTaskId)
        }

        let bgTaskIdConst = bgTaskId
        syncingTask = Task {
            do {
                defer {
                    self.syncWorksitesGuard.store(false, ordering: .sequentiallyConsistent)

                    Task { @MainActor in
                        UIApplication.shared.endBackgroundTask(bgTaskIdConst)
                    }
                }

                if self.syncWorksitesGuard.exchange(true, ordering: .sequentiallyConsistent) {
                    return
                }

                _ = await worksiteChangeRepository.syncWorksites()

                scheduleSyncMedia()
            }
        }
    }
}
