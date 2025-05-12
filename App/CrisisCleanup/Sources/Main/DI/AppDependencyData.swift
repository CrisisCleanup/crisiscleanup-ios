extension MainComponent {
    var appDatabase: AppDatabase {
        shared {
            let database = AppDatabase.shared
            if appEnv.isDebuggable {
                database.logPath()
            }
            return database
        }
    }

    public var databaseVersionProvider: DatabaseVersionProvider { appDatabase }

    public var databaseOperator: DatabaseOperator {
        shared {
            AppDatabaseOperator(appDatabase)
        }
    }

    var languageDao: LanguageDao {
        LanguageDao(appDatabase)
    }

    var incidentDao: IncidentDao {
        IncidentDao(appDatabase)
    }

    var locationDao: LocationDao {
        LocationDao(appDatabase)
    }

    var worksiteDao: WorksiteDao {
        WorksiteDao(
            appDatabase,
            syncLoggerFactory.getLogger("worksite-data"),
            loggerFactory.getLogger("worksites-data")
        )
    }

    var incidentDataSyncParameterDao: IncidentDataSyncParameterDao {
        IncidentDataSyncParameterDao(
            appDatabase,
            loggerFactory.getLogger("sync"),
        )
    }

    var workTypeStatusDao: WorkTypeStatusDao {
        WorkTypeStatusDao(appDatabase)
    }

    var recentWorksiteDao: RecentWorksiteDao {
        RecentWorksiteDao(appDatabase)
    }

    var worksiteFlagDao: WorksiteFlagDao {
        WorksiteFlagDao(appDatabase)
    }

    var worksiteNoteDao: WorksiteNoteDao {
        WorksiteNoteDao(appDatabase)
    }

    var workTypeDao: WorkTypeDao {
        WorkTypeDao(appDatabase)
    }

    var organizationsDao: IncidentOrganizationDao {
        IncidentOrganizationDao(appDatabase)
    }

    var worksiteChangeDao: WorksiteChangeDao {
        WorksiteChangeDao(
            appDatabase,
            uuidGenerator: uuidGenerator,
            changeSerializer: worksiteChangeSerializer,
            appVersionProvider: appVersionProvider,
            syncLogger: syncLoggerFactory.getLogger("worksite-change-dao")
        )
    }

    var networkFileDao: NetworkFileDao {
        NetworkFileDao(appDatabase)
    }

    var localImageDao: LocalImageDao {
        LocalImageDao(appDatabase)
    }

    var workTypeTransferRequestDao: WorkTypeTransferRequestDao {
        WorkTypeTransferRequestDao(appDatabase)
    }

    var personContactDao: PersonContactDao {
        PersonContactDao(appDatabase)
    }

    var caseHistoryDao: CaseHistoryDao {
        CaseHistoryDao(appDatabase)
    }

    var listDao: ListDao {
        ListDao(appDatabase)
    }

    var syncLogDao: SyncLogDao {
        SyncLogDao(appDatabase)
    }

    var uuidGenerator: UuidGenerator {
        SwiftUuidGenerator()
    }

    var worksiteChangeSerializer: WorksiteChangeSerializer {
        SnapshotWorksiteChangeSerializer()
    }

    public var incidentsRepository: IncidentsRepository {
        shared {
            OfflineFirstIncidentsRepository(
                dataSource: networkDataSource,
                appPreferencesDataSource: appPreferences,
                incidentDao: incidentDao,
                locationDao: locationDao,
                incidentOrganizationDao: organizationsDao,
                organizationsSyncer: organizationsSyncer,
                loggerFactory: loggerFactory
            )
        }
    }

    public var workTypeStatusRepository: WorkTypeStatusRepository {
        shared {
            CrisisCleanupWorkTypeStatusRepository(
                dataSource: networkDataSource,
                workTypeStatusDao: workTypeStatusDao,
                loggerFactory: loggerFactory
            )
        }
    }

    public var languageTranslationsRepository: LanguageTranslationsRepository {
        shared {
            OfflineFirstLanguageTranslationsRepository(
                dataSource: networkDataSource,
                appPreferencesDataSource: appPreferences,
                languageDao: languageDao,
                statusRepository: workTypeStatusRepository,
                loggerFactory: loggerFactory
            )
        }
    }

    public var locationsRepository: LocationsRepository {
        shared {
            OfflineFirstLocationsRepository(locationDao)
        }
    }

    public var worksitesRepository: WorksitesRepository {
        shared {
            OfflineFirstWorksitesRepository(
                dataSource: networkDataSource,
                writeApi: writeApi,
                worksiteDao: worksiteDao,
                recentWorksiteDao: recentWorksiteDao,
                workTypeTransferRequestDao: workTypeTransferRequestDao,
                accountDataRepository: accountDataRepository,
                languageTranslationsRepository: languageTranslationsRepository,
                organizationsRepository: organizationsRepository,
                filtersRepository: casesFilterRepository,
                locationManager: locationManager,
                appVersionProvider: appVersionProvider,
                loggerFactory: loggerFactory
            )
        }
    }

    public var searchWorksitesRepository: SearchWorksitesRepository {
        shared {
            MemorySearchWorksitesRepository(
                networkDataSource,
                worksiteDao,
                loggerFactory
            )
        }
    }

    var locationBoundsConverter: LocationBoundsConverter {
        shared {
            CrisisCleanupLocationBoundsConverter(
                loggerFactory: loggerFactory
            )
        }
    }

    public var organizationsRepository: OrganizationsRepository {
        shared {
            OfflineFirstOrganizationsRepository(
                incidentOrganizationDao: organizationsDao,
                locationDao: locationDao,
                networkDataSource: networkDataSource,
                locationBoundsConverter: locationBoundsConverter,
                loggerFactory: loggerFactory
            )
        }
    }

    private var incidentCachePreferences: IncidentCachePreferencesDataSource {
        shared {
            IncidentCachePreferencesUserDefaults()
        }
    }

    private var locationBounder: IncidentLocationBounder {
        shared {
            CrisisCleanupIncidentLocationBounder(
                incidentsRepository: incidentsRepository,
                locationsRepository: locationsRepository,
                loggerFactory: loggerFactory
            )
        }
    }

    var incidentCacheRepository: IncidentCacheRepository {
        shared {
            IncidentWorksitesCacheRepository(
                accountDataRefresher: accountDataRefresher,
                incidentsRepository: incidentsRepository,
                appPreferences: appPreferences,
                syncParameterDao: incidentDataSyncParameterDao,
                incidentCachePreferences: incidentCachePreferences,
                incidentSelector: incidentSelector,
                locationProvider: locationManager,
                locationBounder: locationBounder,
                incidentMapTracker: incidentMapTracker,
                networkDataSource: networkDataSource,
                worksitesRepository: worksitesRepository,
                worksiteDao: worksiteDao,
                speedMonitor: incidentCacheDataDownloadSpeedMonitor,
                networkMonitor: networkMonitor,
                syncLogger: syncLoggerFactory.getLogger("sync"),
                translator: translator,
                appEnv: appEnv,
                appLoggerFactory: loggerFactory
            )
        }
    }

    var localFileCache: LocalFileCache {
        shared {
            MemoryLocalFileCache(loggerFactory: loggerFactory)
        }
    }

    public var worksiteChangeRepository: WorksiteChangeRepository {
        shared {
            CrisisCleanupWorksiteChangeRepository(
                worksiteDao: worksiteDao,
                worksiteChangeDao: worksiteChangeDao,
                worksiteFlagDao: worksiteFlagDao,
                worksiteNoteDao: worksiteNoteDao,
                workTypeDao: workTypeDao,
                localImageDao: localImageDao,
                localFileCache: localFileCache,
                worksiteChangeSyncer: NetworkWorksiteChangeSyncer(
                    changeSetOperator: WorksiteChangeSetOperator(),
                    networkDataSource: networkDataSource,
                    writeApiClient: writeApi,
                    networkMonitor: networkMonitor,
                    appEnv: appEnv
                ),
                worksitePhotoChangeSyncer: WorksitePhotoChangeSyncer(
                    writeApiClient: writeApi
                ),
                accountDataRepository: accountDataRepository,
                networkDataSource: networkDataSource,
                worksitesRepository: worksitesRepository,
                organizationsRepository: organizationsRepository,
                localImageRepository: localImageRepository,
                accountEventBus: accountEventBus,
                worksiteInteractor: worksiteInteractor,
                appEnv: appEnv,
                syncLoggerFactory: syncLoggerFactory,
                loggerFactory: loggerFactory
            )
        }
    }

    public var localImageRepository: LocalImageRepository {
        shared {
            CrisisCleanupLocalImageRepository(
                worksiteDao: worksiteDao,
                networkFileDao: networkFileDao,
                localImageDao: localImageDao,
                writeApi: writeApi,
                localFileCache: localFileCache,
                worksiteInteractor: worksiteInteractor,
                syncLogger: syncLoggerFactory.getLogger("local-image"),
                loggerFactory: loggerFactory
            )
        }
    }

    public var worksiteImageRepository: WorksiteImageRepository {
        shared {
            OfflineFirstWorksiteImageRepository(
                worksiteDao: worksiteDao,
                localImageDao: localImageDao,
                localImageRepository: localImageRepository,
                localFileCache: localFileCache,
                loggerFactory: loggerFactory
            )
        }
    }

    public var usersRepository: UsersRepository {
        shared {
            OfflineFirstUsersRepository(
                networkDataSource: networkDataSource,
                personContactDao: personContactDao,
                incidentOrganizationDao: organizationsDao,
                loggerFactory: loggerFactory
            )
        }
    }

    public var casesFilterRepository: CasesFilterRepository {
        shared {
            CrisisCleanupCasesFilterRepository(
                dataSource: CasesFiltersUserDefaults(),
                locationManager: locationManager,
                networkDataSource: networkDataSource
            )
        }
    }

    public var caseHistoryRepository: CaseHistoryRepository {
        shared {
            OfflineFirstCaseHistoryRepository(
                caseHistoryDao: caseHistoryDao,
                personContactDao: personContactDao,
                worksiteDao: worksiteDao,
                networkDataSource: networkDataSource,
                usersRepository: usersRepository,
                translator: languageTranslationsRepository,
                loggerFactory: loggerFactory
            )
        }
    }

    public var appSupportRepository: AppSupportRepository {
        shared {
            CrisisCleanupAppSupportRepository(
                appVersionProvider: appVersionProvider,
                networkDataSource: networkDataSource,
                appMetricsDataSource: appMetricsDataSource,
                appEnv: appEnv,
                loggerFactory: loggerFactory
            )
        }
    }

    public var orgVolunteerRepository: OrgVolunteerRepository {
        shared {
            CrisisCleanupOrgVolunteerRepository(
                registerApi: registerApi,
                loggerFactory: loggerFactory
            )
        }
    }

    public var requestRedeployRepository: RequestRedeployRepository {
        shared {
            CrisisCleanupRequestRedeployRepository(
                networkDataSource: networkDataSource,
                accountDataRepository: accountDataRepository,
                writeApi: writeApi,
                loggerFactory: loggerFactory
            )
        }
    }

    public var listsRepository: ListsRepository {
        shared {
            CrisisCleanupListsRepository(
                listDao: listDao,
                incidentDao: incidentDao,
                incidentsRepository: incidentsRepository,
                organizationDao: organizationsDao,
                networkDataSource: networkDataSource,
                personContactDao: personContactDao,
                usersRepository: usersRepository,
                worksiteDao: worksiteDao,
                loggerFactory: loggerFactory
            )
        }
    }

    public var shareLocationRepository: ShareLocationRepository {
        shared {
            CrisisCleanupShareLocationRepository(
                accountDataRepository: accountDataRepository,
                appPreferences: appPreferences,
                appSupportRepository: appSupportRepository,
                locationManager: locationManager,
                writeApiClient: writeApi,
                loggerFactory: loggerFactory
            )
        }
    }

    public var appDataManagementRepository: AppDataManagementRepository {
        shared {
            CrisisCleanupDataManagementRepository(
                incidentsRepository: incidentsRepository,
                worksiteChangeRepository: worksiteChangeRepository,
                incidentDataSyncParameterDao: incidentDataSyncParameterDao,
                syncPuller: syncPuller,
                databaseOperator: databaseOperator,
                accountEventBus: accountEventBus,
                loggerFactory: loggerFactory
            )
        }
    }

    var pagingSyncLogRepository: PagingSyncLogRepository {
        shared {
            PagingSyncLogRepository(
                syncLogDao: syncLogDao,
                appEnv: appEnv,
                type: "sync-insights"
            )
        }
    }

    public var syncLogRepository: SyncLogRepository {
        pagingSyncLogRepository
    }

    var incidentCacheDataDownloadSpeedMonitor: DataDownloadSpeedMonitor {
        shared {
            IncidentDataDownloadSpeedMonitor()
        }
    }
}
