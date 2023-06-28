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

    public var incidentDataPullReporter: IncidentDataPullReporter { worksitesRepository as! IncidentDataPullReporter }

    public var syncLoggerFactory: SyncLoggerFactory { shared { DebugSyncLoggerFactory(loggerFactory) } }
}

// TODO: Replace when actual logger is ready
private class DebugSyncLoggerFactory: SyncLoggerFactory {
    private let loggerFactory: AppLoggerFactory

    func getLogger(_ type: String) -> SyncLogger {
        return DebugSyncLogger(loggerFactory.getLogger(type))
    }

    init(_ loggerFactory: AppLoggerFactory) {
        self.loggerFactory = loggerFactory
    }
}

private class DebugSyncLogger: SyncLogger {
    private var logger: AppLogger

    init(_ logger: AppLogger) {
        self.logger = logger
    }

    func clear() -> SyncLogger {
        return self
    }

    func flush() {}

    func log(_ message: String, _ details: String, _ type: String) -> SyncLogger {
        logger.logDebug(type, message, details)
        return self
    }
}
