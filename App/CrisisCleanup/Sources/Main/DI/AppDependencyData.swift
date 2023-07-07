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
        WorksiteChangeDao(appDatabase)
    }

    var workTypeTransferRequestDao: WorkTypeTransferRequestDao {
        WorkTypeTransferRequestDao(appDatabase)
    }

    var personContactDao: PersonContactDao {
        PersonContactDao(appDatabase)
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
                accountDataRepository: accountDataRepository,
                languageTranslationsRepository: languageTranslationsRepository,
                appVersionProvider: appVersionProvider,
                loggerFactory: loggerFactory
            )
        }
    }

    public var searchWorksitesRepository: SearchWorksitesRepository {
        FakeSearchWorksitesRepository()
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
                worksiteChangeSyncer: NetworkWorksiteChangeSyncer(),
                accountDataRepository: accountDataRepository,
                networkDataSource: networkDataSource,
                worksitesRepository: worksitesRepository,
                organizationsRepository: organizationsRepository,
                authEventBus: authEventBus,
                networkMonitor: networkMonitor,
                appEnv: appEnv,
                syncLoggerFactory: syncLoggerFactory,
                loggerFactory: loggerFactory
            )
        }
    }
}
