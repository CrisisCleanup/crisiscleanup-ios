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
    var locationsRepository: LocationsRepository { get }
    var worksitesRepository: WorksitesRepository { get }

    var translator: KeyAssetTranslator { get }

    var authenticateViewBuilder: AuthenticateViewBuilder { get }
    var incidentSelectViewBuilder: IncidentSelectViewBuilder { get }

    var authEventBus: AuthEventBus { get }
    var accountDataRepository: AccountDataRepository { get }

    var syncLoggerFactory: SyncLoggerFactory { get }
    var syncPuller: SyncPuller { get }
    var syncPusher: SyncPusher { get }

    var incidentSelector: IncidentSelector { get }

    var incidentBoundsProvider: IncidentBoundsProvider { get }

    var mapCaseIconProvider: MapCaseIconProvider { get }
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

    public var accountDataRepository: AccountDataRepository {
        let accountDataSource = AccountInfoUserDefaults()
        let secureDataSource = KeychainDataSource()
        return shared {
            CrisisCleanupAccountDataRepository(
                accountDataSource,
                secureDataSource,
                authEventBus,
                loggerFactory
            )
        }
    }

    public var translator: KeyAssetTranslator { languageTranslationsRepository }

    public var authenticateViewBuilder: AuthenticateViewBuilder { self }
    public var incidentSelectViewBuilder: IncidentSelectViewBuilder { self }

    public var authEventBus: AuthEventBus {
        return shared { CrisisCleanupAuthEventBus() }
    }

    public var incidentSelector: IncidentSelector {
        shared {
            IncidentSelectRepository(
                preferencesStore: appPreferences,
                incidentsRepository: incidentsRepository
            )
        }
    }
}
