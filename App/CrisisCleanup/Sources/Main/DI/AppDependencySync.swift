extension MainComponent {
    var providesAppSyncer: AppSyncer {
        shared {
            AppSyncer (
                accountDataRepository: accountDataRepository,
                incidentsRepository: incidentsRepository,
                languageRepository: languageTranslationsRepository,
                statusRepository: workTypeStatusRepository,
                worksitesRepository: worksitesRepository,
                appPreferencesDataStore: appPreferences,
                syncLoggerFactory: syncLoggerFactory,
                authEventBus: authEventBus,
                networkMonitor: networkMonitor
            )
        }
    }

    public var syncPuller: SyncPuller { providesAppSyncer }

    public var syncPusher: SyncPusher { providesAppSyncer }

    var worksitesSyncer: WorksitesSyncer {
        IncidentWorksitesSyncer(
            networkDataSource: networkDataSource,
            networkDataCache: WorksitesNetworkDataFileCache(
                networkDataSource: networkDataSource,
                loggerFactory: loggerFactory
            ),
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

    public var incidentDataPullReporter: IncidentDataPullReporter { worksitesRepository as! IncidentDataPullReporter }

    public var syncLoggerFactory: SyncLoggerFactory {
        shared {
            AppSyncLoggerFactory(
                syncLogDao,
                appEnv
            )
        }
    }
}

private class AppSyncLoggerFactory: SyncLoggerFactory {
    private let syncLogDao: SyncLogDao
    private let appEnv: AppEnv

    init(
        _ syncLogDao: SyncLogDao,
        _ appEnv: AppEnv
    ) {
        self.syncLogDao = syncLogDao
        self.appEnv = appEnv
    }

    func getLogger(_ type: String) -> SyncLogger {
        return PagingSyncLogRepository(
            syncLogDao: syncLogDao,
            appEnv: appEnv,
            type: type
        )
    }
}
