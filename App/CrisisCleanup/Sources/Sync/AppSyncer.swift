import Atomics
import BackgroundTasks
import Combine
import UIKit

public protocol SyncPuller {
    func appPull(_ cancelOngoing: Bool)

    func pullUnauthenticatedData()

    func pullIncidents() async

    func appPullIncident(_ id: Int64)

    func appPullIncidentWorksitesDelta(_ forceRefreshAll: Bool)
}

extension SyncPuller {
    func appPull() {
        appPull(false)
    }
}

public protocol SyncPusher {
    func appPushWorksite(_ worksiteId: Int64, _ scheduleMediaSync: Bool)

    func syncPushWorksitesAsync() async

    func scheduleSyncMedia()

    func scheduleSyncWorksites()
}

extension SyncPusher {
    func appPushWorksite(_ worksiteId: Int64) {
        appPushWorksite(worksiteId, false)
    }
}

class AppSyncer: SyncPuller, SyncPusher {
    private let pullLanguageGuard = ManagedAtomic(false)

    private let accountData: AnyPublisher<AccountData, Never>
    private let appPreferences: AnyPublisher<AppPreferences, Never>

    private let accountDataRepository: AccountDataRepository
    private let accountDataRefresher: AccountDataRefresher
    private let incidentsRepository: IncidentsRepository
    private let languageRepository: LanguageTranslationsRepository
    private let statusRepository: WorkTypeStatusRepository
    private let worksitesRepository: WorksitesRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let localImageRepository: LocalImageRepository
    private let appLogger: AppLogger
    private let syncLogger: SyncLogger
    private let authEventBus: AuthEventBus

    private let pullLock = NSLock()
    private var pullTask: Task<Void, Error>? = nil

    private let pullDeltaLock = NSLock()
    private var pullDeltaTask: Task<Void, Error>? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        accountDataRefresher: AccountDataRefresher,
        incidentsRepository: IncidentsRepository,
        languageRepository: LanguageTranslationsRepository,
        statusRepository: WorkTypeStatusRepository,
        worksitesRepository: WorksitesRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        appPreferencesDataStore: AppPreferencesDataStore,
        localImageRepository: LocalImageRepository,
        appLoggerFactory: AppLoggerFactory,
        syncLoggerFactory: SyncLoggerFactory,
        authEventBus: AuthEventBus
    ) {
        self.accountDataRepository = accountDataRepository
        self.accountDataRefresher = accountDataRefresher
        self.incidentsRepository = incidentsRepository
        self.languageRepository = languageRepository
        self.statusRepository = statusRepository
        self.worksitesRepository = worksitesRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.localImageRepository = localImageRepository
        appLogger = appLoggerFactory.getLogger("sync")
        syncLogger = syncLoggerFactory.getLogger("app-syncer")
        self.authEventBus = authEventBus

        accountData = accountDataRepository.accountData.eraseToAnyPublisher()
        appPreferences = appPreferencesDataStore.preferences.eraseToAnyPublisher()
    }

    // Call from application did finish launching
//    public static func registerBackgroundTasks() {
//        let scheduler = BGTaskScheduler.shared
//        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.pull.rawValue, using: nil) { task in
//            self.pull(task as! BgPullTask)
//        }
//    }

    private func validateAccountTokens() async throws -> Bool {
        await accountDataRepository.updateAccountTokens()
        return try await accountData.asyncFirst().areTokensValid
    }

    private func pull(_ task: BgPullTask) {
        // TODO: Do
    }

    private func getSyncPlan() async throws -> (Bool, Int64) {
        let preferences = try await appPreferences.asyncFirst()
        let recentIncidents = try incidentsRepository.getIncidents(Date.now.addingTimeInterval(-365.days))
        var pullIncidents = recentIncidents.isEmpty
        if !pullIncidents {
            pullIncidents = preferences.syncAttempt.shouldSyncPassively()
        }

        var pullWorksitesIncidentId = Int64(0)
        let incidentId = preferences.selectedIncidentId
        if incidentId > 0 {
            if try incidentsRepository.getIncident(incidentId) != nil {
                let syncStats = try worksitesRepository.getWorksiteSyncStats(incidentId)
                if syncStats?.shouldSync != false {
                    pullWorksitesIncidentId = incidentId
                }
            }
        }

        return (pullIncidents, pullWorksitesIncidentId)
    }

    private func internalPullIncidents() async throws {
        await accountDataRefresher.updateApprovedIncidents(true)
        try await self.incidentsRepository.pullIncidents()
    }

    func appPull(_ cancelOngoing: Bool) {
        pullLock.withLock {
            if cancelOngoing {
                pullTask?.cancel()
            }

            pullTask = Task {
                do {
                    if try await !validateAccountTokens() {
                        return
                    }

                    try Task.checkCancellation()

                    let (pullIncidents, pullWorksitesIncidentId) = try await getSyncPlan()
                    if !pullIncidents && pullWorksitesIncidentId <= 0 {
                        return
                    }

                    try Task.checkCancellation()

                    if pullIncidents {
                        self.syncLogger.log("Pulling incidents")
                        try await internalPullIncidents()
                        self.syncLogger.log("Incidents pulled")
                    }

                    try Task.checkCancellation()

                    // TODO: Prevent multiple incidents from refreshing concurrently.
                    if pullWorksitesIncidentId > 0 {
                        self.syncLogger.log("Refreshing incident \(pullWorksitesIncidentId) worksites")
                        try await self.worksitesRepository.refreshWorksites(pullWorksitesIncidentId)
                        self.syncLogger.log("Incident \(pullWorksitesIncidentId) worksites refreshed")
                    }
                } catch {
                    appLogger.logError(error)
                    // TODO: Handle proper
                    print(error)
                }
            }
        }
    }

    func pullIncidents() async {
        do {
            try await internalPullIncidents()
        } catch {
            appLogger.logError(error)
        }
    }

    func appPullIncident(_ id: Int64) {
        Task {
            do {
                // TODO: Wait for account token and skip if token is invalid
                try await withThrowingTaskGroup(of: Void.self) { group -> Void in
                    group.addTask {
                        try await self.incidentsRepository.pullIncident(id)
                        await self.incidentsRepository.pullIncidentOrganizations(id)
                    }
                    try await group.waitForAll()
                }
            } catch {
                // TODO: Handle proper
                print(error)
            }
        }
    }

    func appPullIncidentWorksitesDelta(_ forceRefreshAll: Bool) {
        pullDeltaLock.withLock {
            pullDeltaTask?.cancel()
            pullDeltaTask = Task {
                do {
                    let incidentId = try await appPreferences.asyncFirst().selectedIncidentId
                    if let syncStats = try worksitesRepository.getWorksiteSyncStats(incidentId),
                       syncStats.isDeltaPull {
                        syncLogger.log("App pull \(incidentId) delta")
                        do {
                            defer {
                                syncLogger.log("App pull \(incidentId) delta end")
                                syncLogger.flush()
                            }

                            try await worksitesRepository.refreshWorksites(
                                incidentId,
                                forceQueryDeltas: !forceRefreshAll,
                                forceRefreshAll: forceRefreshAll
                            )
                        } catch {
                            if !(error is CancellationError) {
                                syncLogger.log("\(incidentId) delta fail \(error)")
                            }
                        }
                    }
                } catch {
                    // TODO: Handle proper
                    print(error)
                }
            }
        }
    }

    private func pullSelectedIncidentWorksites() -> Task<Void, Error> {
        return Task {
            // TODO: Do
            try Task.checkCancellation()
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
                    // TODO: Handle proper
                    print(error)
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
                if try await !validateAccountTokens() {
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
                if try await !validateAccountTokens() {
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

class BgPullTask: BGTask {

}
