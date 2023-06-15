import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
    var loggerFactory: AppLoggerFactory { get }
    var networkMonitor: NetworkMonitor { get }

    var inputValidator: InputValidator { get }

    var networkRequestProvider: NetworkRequestProvider { get }
    var authApi: CrisisCleanupAuthApi { get }
    var networkDataSource: CrisisCleanupNetworkDataSource { get }

    var appPreferences: AppPreferencesDataStore { get }

    var incidentsRepository: IncidentsRepository { get }
    var languageTranslationsRepository: LanguageTranslationsRepository { get }
    var workTypeStatusRepository: WorkTypeStatusRepository { get }

    var authenticateViewBuilder: AuthenticateViewBuilder { get }

    var authEventBus: AuthEventBus { get }
    var accountDataRepository: AccountDataRepository { get }

    var syncPuller: SyncPuller { get }
    var syncPusher: SyncPusher { get }
    var syncLoggerFactory: SyncLoggerFactory { get }
}

extension MainComponent {
    public var appVersionProvider: AppVersionProvider { providesAppVersionProvider }

    public var inputValidator: InputValidator { shared { CommonInputValidator() } }

    var providesAppVersionProvider: AppVersionProvider { shared { AppleAppVersionProvider() } }

    public var networkMonitor: NetworkMonitor {
        shared {
            // TODO: Pass host URL by environment
            NetworkReachability()
        }
    }

    public var networkRequestProvider: NetworkRequestProvider {
        shared { CrisisCleanupNetworkRequestProvider(appSettingsProvider) }
    }

    public var authApi: CrisisCleanupAuthApi {
        AuthApiClient(
            appEnv: appEnv,
            networkRequestProvider: networkRequestProvider
        )
    }
    public var networkDataSource: CrisisCleanupNetworkDataSource {
        DataApiClient(
            appEnv: appEnv,
            networkRequestProvider: networkRequestProvider
        )
    }

    public var appPreferences: AppPreferencesDataStore { shared { AppPreferencesUserDefaults() } }

    public var incidentsRepository: IncidentsRepository { shared { OfflineFirstIncidentsRepository() } }
    public var workTypeStatusRepository: WorkTypeStatusRepository {
        shared {
            CrisisCleanupWorkTypeStatusRepository(
                dataSource: networkDataSource,
                loggerFactory: loggerFactory
            )
        }
    }
    public var languageTranslationsRepository: LanguageTranslationsRepository {
        shared {
            OfflineFirstLanguageTranslationsRepository(
                dataSource: networkDataSource,
                appPreferencesDataStore: appPreferences,
                loggerFactory: loggerFactory
            )
        }
    }

    public var authenticateViewBuilder: AuthenticateViewBuilder { self }

    public var authEventBus: AuthEventBus {
        return shared { CrisisCleanupAuthEventBus() }
    }

    public var accountDataRepository: AccountDataRepository {
        let accountDataSource = AccountInfoUserDefaults()
        let secureDataSource = KeychainDataSource()
        return shared {
            CrisisCleanupAccountDataRepository(
                accountDataSource,
                secureDataSource,
                self.authEventBus,
                self.loggerFactory
            )
        }
    }

    var providesAppSyncer: AppSyncer {
        shared {
            AppSyncer (
                accountDataRepository: accountDataRepository,
                incidentsRepository: incidentsRepository,
                languageRepository: languageTranslationsRepository,
                statusRepository: workTypeStatusRepository,
                appPreferencesDataStore: appPreferences,
                syncLoggerFactory: syncLoggerFactory,
                authEventBus: authEventBus,
                networkMonitor: networkMonitor
            )
        }
    }

    public var syncPuller: SyncPuller { providesAppSyncer }

    public var syncPusher: SyncPusher { providesAppSyncer }

    public var syncLoggerFactory: SyncLoggerFactory { shared { DebugSyncLoggerFactory(loggerFactory) } }
}

// TODO: Replace when actual logger is ready
private class DebugSyncLoggerFactory: SyncLoggerFactory {
    private let loggerFactory: AppLoggerFactory

    func getLogger(_ type: String) -> SyncLogger {
        return DebugSyncLogger(loggerFactory.getLogger(type))
    }

    init(_ loggerFactory: AppLoggerFactory) {
        self.loggerFactory = loggerFactory
    }
}

private class DebugSyncLogger: SyncLogger {
    private var logger: AppLogger

    init(_ logger: AppLogger) {
        self.logger = logger
    }

    func clear() -> SyncLogger {
        return self
    }

    func flush() {}

    func log(_ message: String, _ details: String, _ type: String) -> SyncLogger {
        logger.logDebug(type, message, details)
        return self
    }
}
