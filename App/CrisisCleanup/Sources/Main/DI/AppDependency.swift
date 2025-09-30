import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
    var databaseVersionProvider: DatabaseVersionProvider { get }
    var databaseOperator: DatabaseOperator { get }
    var loggerFactory: AppLoggerFactory { get }
    var networkMonitor: NetworkMonitor { get }
    var systemNotifier: SystemNotifier { get }

    var inputValidator: InputValidator { get }
    var phoneNumberParser: PhoneNumberParser { get }

    var qrCodeGenerator: QrCodeGenerator { get }

    var externalEventBus: ExternalEventBus { get }

    var networkRequestProvider: NetworkRequestProvider { get }
    var authApi: CrisisCleanupAuthApi { get }
    var networkDataSource: CrisisCleanupNetworkDataSource { get }

    var appPreferences: AppPreferencesDataSource { get }

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
    var incidentCacheRepository: IncidentCacheRepository { get }
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
    var listsRepository: ListsRepository { get }
    var shareLocationRepository: ShareLocationRepository { get }
    var appDataManagementRepository: AppDataManagementRepository { get }
    var dataDownloadSpeedMonitor: DataDownloadSpeedMonitor { get }

    var authenticateViewBuilder: AuthenticateViewBuilder { get }
    var incidentSelectViewBuilder: IncidentSelectViewBuilder { get }

    var accountEventBus: AccountEventBus { get }
    var accountDataRepository: AccountDataRepository { get }
    var accountDataRefresher: AccountDataRefresher { get }
    var organizationRefresher: OrganizationRefresher { get }
    var listDataRefresher: ListDataRefresher { get }

    var syncLoggerFactory: SyncLoggerFactory { get }
    var syncPuller: SyncPuller { get }
    var syncPusher: SyncPusher { get }
    var incidentDataPullReporter: IncidentDataPullReporter { get }
    var backgroundTaskCoordinator: BackgroundTaskCoordinator { get }

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
    var incidentMapTracker: IncidentMapTracker { get }
}

extension MainComponent {
    public var appVersionProvider: AppVersionProvider { providesAppVersionProvider }

    public var inputValidator: InputValidator { CommonInputValidator() }
    public var phoneNumberParser: PhoneNumberParser { RegexPhoneNumberParser() }

    var providesAppVersionProvider: AppVersionProvider { shared { AppleAppVersionProvider() } }

    public var networkMonitor: NetworkMonitor {
        shared {
            AppNetworkMonitor()
        }
    }

    public var systemNotifier: SystemNotifier {
        shared {
            AppSystemNotifier(loggerFactory: loggerFactory)
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
                accountEventBus: accountEventBus,
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
                accountEventBus: accountEventBus,
                appEnv: appEnv
            )
        }
    }
    var accountApi: CrisisCleanupAccountApi {
        shared {
            AccountApiClient(
                networkRequestProvider: networkRequestProvider,
                accountDataRepository: accountDataRepository,
                authApiClient: authApi,
                accountEventBus: accountEventBus,
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
                accountEventBus: accountEventBus,
                appEnv: appEnv
            )
        }
    }

    public var appPreferences: AppPreferencesDataSource { shared { AppPreferencesUserDefaults() } }

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
                accountEventBus,
                authApi,
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
                incidentClaimThresholdRepository: incidentClaimThresholdRepository,
                accountEventBus: accountEventBus,
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

    var appMaintenanceDataSource: AppMaintenanceDataSource {
        shared {
            AppMaintenanceUserDefaults()
        }
    }

    public var translator: KeyAssetTranslator { languageTranslationsRepository }

    public var authenticateViewBuilder: AuthenticateViewBuilder { self }
    public var incidentSelectViewBuilder: IncidentSelectViewBuilder { self }

    public var accountEventBus: AccountEventBus {
        return shared { CrisisCleanupAccountEventBus() }
    }

    public var incidentSelector: IncidentSelector {
        shared {
            IncidentSelectRepository(
                accountDataRepository: accountDataRepository,
                preferencesStore: appPreferences,
                incidentsRepository: incidentsRepository,
                loggerFactory: loggerFactory,
            )
        }
    }

    public var locationManager: LocationManager {
        shared {
            LocationManager(loggerFactory: loggerFactory)
        }
    }
}
