extension MainComponent {
    private var appSyncer: AppSyncer {
        shared {
            AppSyncer (
                accountDataRepository: accountDataRepository,
                accountDataRefresher: accountDataRefresher,
                incidentsRepository: incidentsRepository,
                languageRepository: languageTranslationsRepository,
                statusRepository: workTypeStatusRepository,
                worksitesRepository: worksitesRepository,
                worksiteChangeRepository: worksiteChangeRepository,
                appPreferencesDataStore: appPreferences,
                localImageRepository: localImageRepository,
                appLoggerFactory: loggerFactory,
                syncLoggerFactory: syncLoggerFactory,
                accountEventBus: accountEventBus
            )
        }
    }

    public var syncPuller: SyncPuller { appSyncer }

    public var syncPusher: SyncPusher { appSyncer }

    private var worksitesNetworkDataCache: WorksitesNetworkDataCache {
        WorksitesNetworkDataFileCache(
            networkDataSource: networkDataSource,
            loggerFactory: loggerFactory
        )
    }

    var worksitesSyncer: WorksitesSyncer {
        IncidentWorksitesSyncer(
            networkDataSource: networkDataSource,
            networkDataCache: worksitesNetworkDataCache,
            worksiteDao: worksiteDao,
            worksiteSyncStatDao: worksiteSyncStatDao,
            appVersionProvider: appVersionProvider,
            loggerFactory: loggerFactory
        )
    }

    var organizationsSyncer: OrganizationsSyncer {
        IncidentOrganizationSyncer(
            networkDataSource: networkDataSource,
            networkDataCache: IncidentOrganizationsDataFileCache(loggerFactory: loggerFactory),
            incidentOrganizationDao: organizationsDao,
            personContactDao: personContactDao,
            appVersionProvider: appVersionProvider,
            loggerFactory: loggerFactory
        )
    }

    var worksitesSecondarySyncer: WorksitesSecondaryDataSyncer {
        IncidentWorksitesSecondaryDataSyncer(
            networkDataSource: networkDataSource,
            networkDataCache: worksitesNetworkDataCache,
            worksiteDao: worksiteDao,
            worksiteSyncStatDao: worksiteSyncStatDao,
            appVersionProvider: appVersionProvider,
            loggerFactory: loggerFactory
        )
    }

    public var incidentDataPullReporter: IncidentDataPullReporter { worksitesRepository as! IncidentDataPullReporter }

    var listsSyncer: ListsSyncer {
        AccountListsSyncer(
            networkDataSource: networkDataSource,
            listsRepository: listsRepository,
            loggerFactory: loggerFactory
        )
    }

    public var syncLoggerFactory: SyncLoggerFactory {
        shared {
            AppSyncLoggerFactory(
                syncLogDao,
                pagingSyncLogRepository,
                appEnv
            )
        }
    }
}

private class AppSyncLoggerFactory: SyncLoggerFactory {
    private let syncLogDao: SyncLogDao
    private let syncLogger: SyncLogger
    private let appEnv: AppEnv

    init(
        _ syncLogDao: SyncLogDao,
        _ syncLogRepository: PagingSyncLogRepository,
        _ appEnv: AppEnv
    ) {
        self.syncLogDao = syncLogDao
        self.syncLogger = syncLogRepository
        self.appEnv = appEnv
    }

    func getLogger(_ type: String) -> SyncLogger {
        syncLogger
    }
}
