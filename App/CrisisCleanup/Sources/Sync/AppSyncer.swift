import Atomics
import BackgroundTasks
import Combine

public protocol SyncPuller {
    func appPull(_ cancelOngoing: Bool)
    func stopPull()

    func pullUnauthenticatedData()

    func appPullIncident(_ id: Int64)
    func stopPullIncident()
}

extension SyncPuller {
    func appPull() {
        appPull(false)
    }
}

public protocol SyncPusher {

}

class AppSyncer: SyncPuller, SyncPusher {
    private let pullLock = NSLock()
    private var pullOperation: Operation? = nil

    private let pullLanguageGuard = ManagedAtomic<Bool>(false)

    private var accountData: AccountData = emptyAccountData
    private var isOnline: Bool = false
    private var appPreferences: AppPreferences = AppPreferences()

    private let incidentsRepository: IncidentsRepository
    private let languageRepository: LanguageTranslationsRepository
    private let statusRepository: WorkTypeStatusRepository
    private let syncLogger: SyncLogger
    private let authEventBus: AuthEventBus

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        languageRepository: LanguageTranslationsRepository,
        statusRepository: WorkTypeStatusRepository,
        appPreferencesDataStore: AppPreferencesDataStore,
        syncLoggerFactory: SyncLoggerFactory,
        authEventBus: AuthEventBus,
        networkMonitor: NetworkMonitor
    ) {
        self.incidentsRepository = incidentsRepository
        self.languageRepository = languageRepository
        self.statusRepository = statusRepository
        syncLogger = syncLoggerFactory.getLogger("")
        self.authEventBus = authEventBus

        networkMonitor.isOnline
            .assign(to: \.isOnline, on: self)
            .store(in: &disposables)

        accountDataRepository.accountData
            .assign(to: \.accountData, on: self)
            .store(in: &disposables)

        appPreferencesDataStore.preferences
            .assign(to: \.appPreferences, on: self)
            .store(in: &disposables)

        let scheduler = BGTaskScheduler.shared
        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.pull.rawValue, using: nil) {task in
            self.pull(task as! BgPullTask)
        }
    }

    private var isValidAccountToken: Bool { !accountData.isTokenInvalid && isOnline }

    private var isSyncPossible: Bool { isValidAccountToken }

    private func pull(_ task: BgPullTask) {
        // TODO:
    }

    func appPull(_ cancelOngoing: Bool) {

    }

    func stopPull() {
        pullLock.withLock {
            pullOperation?.cancel()
        }
    }

    func appPullIncident(_ id: Int64) {

    }

    func stopPullIncident() {

    }

    private func pullIncidents() -> Task<Void, Error> {
        return Task {
            try Task.checkCancellation()
        }
    }

    private func pullSelectedIncidentWorksites() -> Task<Void, Error> {
        return Task {
            try Task.checkCancellation()
        }
    }

    func pullUnauthenticatedData() {
        if !isOnline { return }
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
}

class BgPullTask: BGTask {

}
