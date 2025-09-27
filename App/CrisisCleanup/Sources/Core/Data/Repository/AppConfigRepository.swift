import Combine

public protocol AppConfigRepository {
    var appConfig: any Publisher<AppConfig, Never> { get }

    func pullAppConfig() async
}

class CrisisCleanupAppConfigRepository: AppConfigRepository {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let appConfigDataSource: AppConfigDataSource
    private let logger: AppLogger

    let appConfig: any Publisher<AppConfig, Never>

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        appConfigDataSource: AppConfigDataSource,
        loggerFactory: AppLoggerFactory,
    ) {
        self.networkDataSource = networkDataSource
        self.appConfigDataSource = appConfigDataSource
        logger = loggerFactory.getLogger("app-config")

        appConfig = appConfigDataSource.appConfig
    }


    public func pullAppConfig() async {
        do {
            let thresholds = try await networkDataSource.getClaimThresholds()
            appConfigDataSource.setClaimThresholds(
                thresholds.workTypeCount,
                thresholds.workTypeClosedRatio,
            )
        } catch {
            logger.logError(error)
        }
    }
}
