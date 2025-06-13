extension MainComponent {
    private var appSyncer: AppSyncer {
        shared {
            AppSyncer (
                accountDataRepository: accountDataRepository,
                incidentCacheRepository: incidentCacheRepository,
                languageRepository: languageTranslationsRepository,
                statusRepository: workTypeStatusRepository,
                worksiteChangeRepository: worksiteChangeRepository,
                appPreferencesDataSource: appPreferences,
                localImageRepository: localImageRepository,
                incidentDataPullReporter: incidentDataPullReporter,
                systemNotifier: systemNotifier,
                translator: translator,
                appLoggerFactory: loggerFactory,
                syncLoggerFactory: syncLoggerFactory,
            )
        }
    }

    public var syncPuller: SyncPuller { appSyncer }

    public var syncPusher: SyncPusher { appSyncer }

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

    public var incidentDataPullReporter: IncidentDataPullReporter {
        incidentCacheRepository as! IncidentDataPullReporter
    }

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

    public var backgroundTaskCoordinator: BackgroundTaskCoordinator {
        shared {
            AppBackgroundTaskCoordinator(
                syncPuller: syncPuller,
                syncPusher: syncPusher,
                worksiteChangeRepository: worksiteChangeRepository,
                loggerFactory: loggerFactory
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
