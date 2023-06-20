extension MainComponent {
    var providesAppSyncer: AppSyncer {
        shared {
            AppSyncer (
                accountDataRepository: accountDataRepository,
                incidentsRepository: incidentsRepository,
                languageRepository: languageTranslationsRepository,
                statusRepository: workTypeStatusRepository,
                appPreferencesDataStore: appPreferences,
                syncLoggerFactory: syncLoggerFactory,
                authEventBus: authEventBus,
                networkMonitor: networkMonitor
            )
        }
    }

    public var syncPuller: SyncPuller { providesAppSyncer }

    public var syncPusher: SyncPusher { providesAppSyncer }

    public var syncLoggerFactory: SyncLoggerFactory { shared { DebugSyncLoggerFactory(loggerFactory) } }

    public var incidentSelector: IncidentSelector {
        shared {
            IncidentSelectRepository(
                preferencesStore: appPreferences,
                incidentsRepository: incidentsRepository
            )
        }
    }
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
