import Atomics
import BackgroundTasks
import Combine

public protocol SyncPuller {
    func appPull(_ cancelOngoing: Bool)

    func pullUnauthenticatedData()

    func appPullIncident(_ id: Int64)
}

extension SyncPuller {
    func appPull() {
        appPull(false)
    }
}

public protocol SyncPusher {

}

class AppSyncer: SyncPuller, SyncPusher {
    private let pullLanguageGuard = ManagedAtomic<Bool>(false)

    private var accountData: AccountData = emptyAccountData
    private var appPreferences: AppPreferences = AppPreferences()

    private let incidentsRepository: IncidentsRepository
    private let languageRepository: LanguageTranslationsRepository
    private let statusRepository: WorkTypeStatusRepository
    private let syncLogger: SyncLogger
    private let authEventBus: AuthEventBus

    private let pullLock = NSLock()
    private var pullTask: Task<Void, Error>? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        languageRepository: LanguageTranslationsRepository,
        statusRepository: WorkTypeStatusRepository,
        appPreferencesDataStore: AppPreferencesDataStore,
        syncLoggerFactory: SyncLoggerFactory,
        authEventBus: AuthEventBus,
        // TODO: isOnline signal is not reliable. Find a better way or do without.
        networkMonitor: NetworkMonitor
    ) {
        self.incidentsRepository = incidentsRepository
        self.languageRepository = languageRepository
        self.statusRepository = statusRepository
        syncLogger = syncLoggerFactory.getLogger("")
        self.authEventBus = authEventBus

        accountDataRepository.accountData
            .assign(to: \.accountData, on: self)
            .store(in: &disposables)

        appPreferencesDataStore.preferences
            .assign(to: \.appPreferences, on: self)
            .store(in: &disposables)

        let scheduler = BGTaskScheduler.shared
        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.pull.rawValue, using: nil) { task in
            self.pull(task as! BgPullTask)
        }
    }

    private var isValidAccountToken: Bool { !accountData.isTokenInvalid }

    private var isSyncPossible: Bool { isValidAccountToken }

    private func pull(_ task: BgPullTask) {
        // TODO: Do
    }

    private func pullIncidents() async throws {
        try await incidentsRepository.pullIncidents()
    }

    func appPull(_ cancelOngoing: Bool) {
        pullLock.withLock {
            if cancelOngoing {
                pullTask?.cancel()
            }

            pullTask = Task {
                do {
                    // TODO: Wait for account token and skip if token is invalid
                    try await withThrowingTaskGroup(of: Void.self) { group -> Void in
                        group.addTask { try await self.incidentsRepository.pullIncidents() }
                        try await group.waitForAll()
                    }
                } catch {
                    // TODO: Handle proper
                    print(error)
                }
            }
        }
    }

    func appPullIncident(_ id: Int64) {
        Task {
            do {
                // TODO: Wait for account token and skip if token is invalid
                try await withThrowingTaskGroup(of: Void.self) { group -> Void in
                    group.addTask { try await self.incidentsRepository.pullIncident(id) }
                    try await group.waitForAll()
                }
            } catch {
                // TODO: Handle proper
                print(error)
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
}

class BgPullTask: BGTask {

}
