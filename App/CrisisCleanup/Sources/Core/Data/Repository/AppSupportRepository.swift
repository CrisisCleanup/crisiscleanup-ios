import Combine

public protocol AppSupportRepository {
    var appMetrics: any Publisher<AppMetrics, Never> { get }
    var isAppUpdateAvailable: any Publisher<Bool, Never> { get }

    func onAppOpen()

    func pullAppVersionInfo()
}

class CrisisCleanupAppSupportRepository: AppSupportRepository {
    private let appVersionProvider: AppVersionProvider
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let appMetricsDataSource: AppMetricsDataSource
    private let appEnv: AppEnv
    private let logger: AppLogger

    let appMetrics: any Publisher<AppMetrics, Never>
    let isAppUpdateAvailable: any Publisher<Bool, Never>

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

        let metrics = appMetricsDataSource.metrics
        appMetrics = metrics

        isAppUpdateAvailable = metrics.mapLatest {
            appVersionProvider.buildNumber < ($0.publishedBuild ?? 0)
        }
    }

    func onAppOpen() {
        appMetricsDataSource.setAppOpen(appVersionProvider.buildNumber)
    }

    func pullAppVersionInfo() {
        if appEnv.isProduction {
            Task {
                if let info = await networkDataSource.getAppSupportInfo(appEnv.isNotProduction) {
                    appMetricsDataSource.setAppVersions(
                        MinSupportedAppVersion(
                            minBuild: info.minBuildVersion,
                            title: info.title,
                            message: info.message,
                            link: info.link
                        ),
                        info.publishedVersion ?? 0,
                    )
                } else {
                    logger.logError(GenericError("Unable to contact app support API for minimum support version"))
                }
            }
        }
    }
}
