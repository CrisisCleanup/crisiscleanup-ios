import Atomics
import BackgroundTasks
import Combine

public protocol SyncPuller {
    func appPull(_ cancelOngoing: Bool)

    func pullUnauthenticatedData()

    func appPullIncident(_ id: Int64)

    func appPullIncidentWorksitesDelta()
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

    private var accountData: AnyPublisher<AccountData, Never>
    private var appPreferences: AnyPublisher<AppPreferences, Never>

    private let incidentsRepository: IncidentsRepository
    private let languageRepository: LanguageTranslationsRepository
    private let statusRepository: WorkTypeStatusRepository
    private let worksitesRepository: WorksitesRepository
    private let syncLogger: SyncLogger
    private let authEventBus: AuthEventBus

    private let pullLock = NSLock()
    private var pullTask: Task<Void, Error>? = nil

    private let pullDeltaLock = NSLock()
    private var pullDeltaTask: Task<Void, Error>? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        languageRepository: LanguageTranslationsRepository,
        statusRepository: WorkTypeStatusRepository,
        worksitesRepository: WorksitesRepository,
        appPreferencesDataStore: AppPreferencesDataStore,
        syncLoggerFactory: SyncLoggerFactory,
        authEventBus: AuthEventBus,
        // TODO: isOnline signal is not reliable. Find a better way or do without.
        networkMonitor: NetworkMonitor
    ) {
        self.incidentsRepository = incidentsRepository
        self.languageRepository = languageRepository
        self.statusRepository = statusRepository
        self.worksitesRepository = worksitesRepository
        syncLogger = syncLoggerFactory.getLogger("app-syncer")
        self.authEventBus = authEventBus

        accountData = accountDataRepository.accountData.eraseToAnyPublisher()
        appPreferences = appPreferencesDataStore.preferences.eraseToAnyPublisher()

        let scheduler = BGTaskScheduler.shared
        scheduler.register(forTaskWithIdentifier: BackgroundTaskType.pull.rawValue, using: nil) { task in
            self.pull(task as! BgPullTask)
        }
    }

    private func isValidAccountToken() async throws -> Bool {
        let isInvalid = try await accountData.asyncFirst().isTokenInvalid
        return !isInvalid
    }

    private func isSyncPossible() async throws -> Bool { try await isValidAccountToken() }

    private func pull(_ task: BgPullTask) {
        // TODO: Do
    }

    private func pullIncidents() async throws {
        try await incidentsRepository.pullIncidents()
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

    func appPull(_ cancelOngoing: Bool) {
        pullLock.withLock {
            if cancelOngoing {
                pullTask?.cancel()
            }

            pullTask = Task {
                do {
                    let (pullIncidents, pullWorksitesIncidentId) = try await getSyncPlan()
                    if !pullIncidents && pullWorksitesIncidentId <= 0 {
                        return
                    }

                    // TODO: Wait for account token and skip if token is invalid

                    try await withThrowingTaskGroup(of: Void.self) { group -> Void in
                        group.addTask {
                            try Task.checkCancellation()

                            if pullIncidents {
                                _ = self.syncLogger.log("Pulling incidents")
                                try await self.incidentsRepository.pullIncidents()
                                _ = self.syncLogger.log("Incidents pulled")
                            }

                            try Task.checkCancellation()

                            // TODO: Prevent multiple incidents from refreshing concurrently.
                            if pullWorksitesIncidentId > 0 {
                                _ = self.syncLogger.log("Refreshing incident \(pullWorksitesIncidentId) worksites")
                                try await self.worksitesRepository.refreshWorksites(pullWorksitesIncidentId)
                                _ = self.syncLogger.log("Incident \(pullWorksitesIncidentId) worksites refreshed")
                            }
                        }
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

    func appPullIncidentWorksitesDelta() {
        pullDeltaLock.withLock {
            pullDeltaTask?.cancel()
            pullDeltaTask = Task {
                do {
                    let incidentId = try await appPreferences.asyncFirst().selectedIncidentId
                    if let _ = try incidentsRepository.getIncident(incidentId),
                       let syncStats = try worksitesRepository.getWorksiteSyncStats(incidentId),
                       syncStats.isDeltaPull {
                        _ = syncLogger.log("App pull \(incidentId) delta")
                        do {
                            defer {
                                syncLogger.log("App pull \(incidentId) delta end")
                                    .flush()
                            }

                            try await worksitesRepository.refreshWorksites(
                                incidentId,
                                forceQueryDeltas: true,
                                forceRefreshAll: false
                            )
                        } catch {
                            if !(error is CancellationError) {
                                _ = syncLogger.log("\(incidentId) delta fail \(error)")
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
}

class BgPullTask: BGTask {

}
