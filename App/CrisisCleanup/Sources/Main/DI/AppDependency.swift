import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
    var databaseVersionProvider: DatabaseVersionProvider { get }
    var loggerFactory: AppLoggerFactory { get }
    var networkMonitor: NetworkMonitor { get }

    var inputValidator: InputValidator { get }

    var qrCodeGenerator: QrCodeGenerator { get }

    var externalEventBus: ExternalEventBus { get }

    var networkRequestProvider: NetworkRequestProvider { get }
    var authApi: CrisisCleanupAuthApi { get }
    var networkDataSource: CrisisCleanupNetworkDataSource { get }

    var appPreferences: AppPreferencesDataStore { get }

    var translator: KeyAssetTranslator { get }

    var accessTokenDecoder: AccessTokenDecoder { get }
    var accountUpdateRepository: AccountUpdateRepository { get }

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
    var worksiteImageRepository: WorksiteImageRepository { get }
    var usersRepository: UsersRepository { get }
    var casesFilterRepository: CasesFilterRepository { get }
    var caseHistoryRepository: CaseHistoryRepository { get }
    var appSupportRepository: AppSupportRepository { get }
    var orgVolunteerRepository: OrgVolunteerRepository { get }
    var requestRedeployRepository: RequestRedeployRepository { get }

    var authenticateViewBuilder: AuthenticateViewBuilder { get }
    var incidentSelectViewBuilder: IncidentSelectViewBuilder { get }

    var authEventBus: AuthEventBus { get }
    var accountDataRepository: AccountDataRepository { get }
    var accountDataRefresher: AccountDataRefresher { get }
    var organizationRefresher: OrganizationRefresher { get }
    var listDataRefresher: ListDataRefresher { get }

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
    var worksiteInteractor: WorksiteInteractor { get }
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

    public var qrCodeGenerator: QrCodeGenerator {
        CoreImageQrCodeGenerator()
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
    public var networkDataSource: CrisisCleanupNetworkDataSource {
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
    var accountApi: CrisisCleanupAccountApi {
        shared {
            AccountApiClient(
                networkRequestProvider: networkRequestProvider,
                appEnv: appEnv
            )
        }
    }
    var registerApi: CrisisCleanupRegisterApi {
        shared {
            RegisterApiClient(
                networkRequestProvider: networkRequestProvider,
                accountDataRepository: accountDataRepository,
                authApiClient: authApi,
                authEventBus: authEventBus,
                appEnv: appEnv
            )
        }
    }

    public var appPreferences: AppPreferencesDataStore { shared { AppPreferencesUserDefaults() } }

    var accountDataSource: AccountInfoDataSource {
        shared {
            AccountInfoUserDefaults()
        }
    }

    public var accountDataRepository: AccountDataRepository {
        let secureDataSource = KeychainDataSource()
        return shared {
            CrisisCleanupAccountDataRepository(
                accountDataSource,
                secureDataSource,
                appPreferences,
                authEventBus,
                authApi,
                accountApi,
                loggerFactory,
                appEnv
            )
        }
    }

    public var accountDataRefresher: AccountDataRefresher {
        shared {
            AccountDataRefresher(
                dataSource: accountDataSource,
                networkDataSource: networkDataSource,
                accountDataRepository: accountDataRepository,
                organizationsRepository: organizationsRepository,
                loggerFactory: loggerFactory
            )
        }
    }
    public var organizationRefresher: OrganizationRefresher {
        shared {
            OrganizationRefresher(accountDataRefresher)
        }
    }

    public var listDataRefresher: ListDataRefresher {
        shared {
            ListDataRefresher(
                listsSyncer: listsSyncer,
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
                accountDataRepository: accountDataRepository,
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
