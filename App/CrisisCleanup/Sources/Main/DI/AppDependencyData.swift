extension MainComponent {
    var appDatabase: AppDatabase { shared { .shared } }

    public var databaseVersionProvider: DatabaseVersionProvider { appDatabase }

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
        WorksiteDao(appDatabase, syncLoggerFactory.getLogger("worksite-dao"))
    }

    var worksiteSyncStatDao: WorksiteSyncStatDao {
        WorksiteSyncStatDao(appDatabase)
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
                appPreferencesDataStore: appPreferences,
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
                appPreferencesDataStore: appPreferences,
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
                worksitesSyncer: worksitesSyncer,
                worksiteSyncStatDao: worksiteSyncStatDao,
                worksiteDao: worksiteDao,
                recentWorksiteDao: recentWorksiteDao,
                workTypeTransferRequestDao: workTypeTransferRequestDao,
                accountDataRepository: accountDataRepository,
                languageTranslationsRepository: languageTranslationsRepository,
                appVersionProvider: appVersionProvider,
                loggerFactory: loggerFactory
            )
        }
    }

    public var searchWorksitesRepository: SearchWorksitesRepository {
        shared {
            MemorySearchWorksitesRepository(
                networkDataSource,
                loggerFactory
            )
        }
    }

    public var organizationsRepository: OrganizationsRepository {
        shared {
            OfflineFirstOrganizationsRepository(
                incidentOrganizationDao: organizationsDao,
                networkDataSource: networkDataSource,
                loggerFactory: loggerFactory
            )
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
                authEventBus: authEventBus,
                networkMonitor: networkMonitor,
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
                syncLogger: syncLoggerFactory.getLogger("local-image"),
                loggerFactory: loggerFactory
            )
        }
    }

    public var databaseManagementRepository: DatabaseManagementRepository {
        shared {
            CrisisCleanupDatabaseManagementRepository(
            )
        }
    }

    public var usersRepository: UsersRepository {
        shared {
            OfflineFirstUsersRepository(
                networkDataSource: networkDataSource,
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
}
