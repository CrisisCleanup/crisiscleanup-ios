import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
    var databaseVersionProvider: DatabaseVersionProvider { get }
    var loggerFactory: AppLoggerFactory { get }
    var networkMonitor: NetworkMonitor { get }

    var inputValidator: InputValidator { get }

    var networkRequestProvider: NetworkRequestProvider { get }
    var authApi: CrisisCleanupAuthApi { get }

    var appPreferences: AppPreferencesDataStore { get }

    var translator: KeyAssetTranslator { get }

    var incidentsRepository: IncidentsRepository { get }
    var languageTranslationsRepository: LanguageTranslationsRepository { get }
    var workTypeStatusRepository: WorkTypeStatusRepository { get }
    var locationsRepository: LocationsRepository { get }
    var worksitesRepository: WorksitesRepository { get }
    var searchWorksitesRepository: SearchWorksitesRepository { get }
    var organizationsRepository: OrganizationsRepository { get }
    var worksiteChangeRepository: WorksiteChangeRepository  { get }
    var syncLogRepository: SyncLogRepository  { get }
    var addressSearchRepository: AddressSearchRepository { get }
    var localImageRepository: LocalImageRepository { get }
    var usersRepository: UsersRepository { get }
    var casesFilterRepository: CasesFilterRepository { get }
    var caseHistoryRepository: CaseHistoryRepository { get }
    var appSupportRepository: AppSupportRepository { get }

    var authenticateViewBuilder: AuthenticateViewBuilder { get }
    var incidentSelectViewBuilder: IncidentSelectViewBuilder { get }

    var authEventBus: AuthEventBus { get }
    var accountDataRepository: AccountDataRepository { get }
    var accountDataRefresher: AccountDataRefresher { get }

    var syncLoggerFactory: SyncLoggerFactory { get }
    var syncPuller: SyncPuller { get }
    var syncPusher: SyncPusher { get }
    var incidentDataPullReporter: IncidentDataPullReporter { get }

    var incidentSelector: IncidentSelector { get }

    var locationManager: LocationManager { get }

    var incidentBoundsProvider: IncidentBoundsProvider { get }

    var mapCaseIconProvider: MapCaseIconProvider { get }
    var editableWorksiteProvider: EditableWorksiteProvider { get }
    var worksiteLocationEditor: WorksiteLocationEditor { get }
    var incidentRefresher: IncidentRefresher { get }
    var languageRefresher: LanguageRefresher { get }
    var transferWorkTypeProvider: TransferWorkTypeProvider { get }
    var worksiteProvider: WorksiteProvider { get }
    var existingWorksiteSelector: ExistingWorksiteSelector { get }
}

extension MainComponent {
    public var appVersionProvider: AppVersionProvider { providesAppVersionProvider }

    public var inputValidator: InputValidator { shared { CommonInputValidator() } }

    var providesAppVersionProvider: AppVersionProvider { shared { AppleAppVersionProvider() } }

    public var networkMonitor: NetworkMonitor {
        shared {
            NetworkReachability(appSettingsProvider.reachabilityHost)
        }
    }

    public var networkRequestProvider: NetworkRequestProvider {
        shared { CrisisCleanupNetworkRequestProvider(appSettingsProvider) }
    }

    public var authApi: CrisisCleanupAuthApi {
        shared {
            AuthApiClient(
                appEnv: appEnv,
                networkRequestProvider: networkRequestProvider
            )
        }
    }
    var networkDataSource: CrisisCleanupNetworkDataSource {
        shared {
            DataApiClient(
                networkRequestProvider: networkRequestProvider,
                accountDataRepository: accountDataRepository,
                authApiClient: authApi,
                authEventBus: authEventBus,
                appEnv: appEnv
            )
        }
    }
    var writeApi: CrisisCleanupWriteApi {
        shared {
            WriteApiClient(
                networkRequestProvider: networkRequestProvider,
                accountDataRepository: accountDataRepository,
                authApiClient: authApi,
                authEventBus: authEventBus,
                appEnv: appEnv
            )
        }
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
                authApi,
                loggerFactory,
                appEnv
            )
        }
    }

    public var accountDataRefresher: AccountDataRefresher {
        shared {
            AccountDataRefresher(
                networkDataSource: networkDataSource,
                accountDataRepository: accountDataRepository,
                organizationsRepository: organizationsRepository,
                loggerFactory: loggerFactory
            )
        }
    }

    var appMetricsDataSource: AppMetricsDataSource {
        shared {
            LocalAppMetricsDataSource()
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

    public var locationManager: LocationManager {
        shared {
            LocationManager()
        }
    }
}
