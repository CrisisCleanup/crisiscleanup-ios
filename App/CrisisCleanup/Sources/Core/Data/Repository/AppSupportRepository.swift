import Combine

public protocol AppSupportRepository {
    var appMetrics: any Publisher<AppMetrics, Never> { get }

    func onAppOpen()

    func pullMinSupportedAppVersion()
}

class CrisisCleanupAppSupportRepository: AppSupportRepository {
    private let appVersionProvider: AppVersionProvider
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let appMetricsDataSource: AppMetricsDataSource
    private let appEnv: AppEnv
    private let logger: AppLogger

    let appMetrics: any Publisher<AppMetrics, Never>

    init(
        appVersionProvider: AppVersionProvider,
        networkDataSource: CrisisCleanupNetworkDataSource,
        appMetricsDataSource: AppMetricsDataSource,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory
    ) {
        self.appVersionProvider = appVersionProvider
        self.networkDataSource = networkDataSource
        self.appMetricsDataSource = appMetricsDataSource
        self.appEnv = appEnv
        logger = loggerFactory.getLogger("app-support-repository")

        appMetrics = appMetricsDataSource.metrics
    }

    func onAppOpen() {
        appMetricsDataSource.setAppOpen(appVersionProvider.buildNumber)
    }

    func pullMinSupportedAppVersion() {
        Task {
            if let info = await networkDataSource.getAppSupportInfo(appEnv.isNotProduction) {
                appMetricsDataSource.setMinSupportedVersion(MinSupportedAppVersion(
                    minBuild: info.minBuildVersion,
                    title: info.link,
                    message: info.message,
                    link: info.link
                ))
            } else {
                logger.logError(GenericError("Unable to contact app support API for minimum support version"))
            }
        }
    }
}
