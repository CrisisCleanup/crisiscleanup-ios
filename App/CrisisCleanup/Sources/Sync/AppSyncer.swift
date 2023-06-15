import BackgroundTasks
import Combine

public protocol SyncPuller {
    func appPull(_ cancelOngoing: Bool)
    func stopPull()

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
    private let pullLock: NSLock = NSLock()
    private var pullOperation: Operation? = nil

    private let pullLanguageLock: NSLock = NSLock()

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

    private var isValidAccountToken: Bool { !accountData.isTokenInvalid }

    private var isSyncPossible: Bool { isValidAccountToken && isOnline }

    private func pull(_ task: BgPullTask) {
        // TODO:
    }

    func appPull(_ cancelOngoing: Bool) {

    }

    func stopPull() {
        pullLock.lock()
        pullOperation?.cancel()
        pullLock.unlock()
    }

    func appPullIncident(_ id: Int64) {

    }

    func stopPullIncident() {

    }

    private func pullLanguage() async throws {
//        if pullLanguageLock.try() {
//            defer { pullLanguageLock.unlock() }
//
//        }
    }

    private func pullStatuses() async throws {

    }

    private func pullIncidents() async throws {

    }

    private func pullSelectedIncidentWorksites() async throws {

    }
}

class BgPullTask: BGTask {

}
