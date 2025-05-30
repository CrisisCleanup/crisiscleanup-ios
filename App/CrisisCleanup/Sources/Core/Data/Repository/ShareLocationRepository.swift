import Foundation

public protocol ShareLocationRepository {
    func shareLocation() async
}

class CrisisCleanupShareLocationRepository: ShareLocationRepository {
    private let accountDataRepository: AccountDataRepository
    private let appPreferences: AppPreferencesDataSource
    private let appSupportRepository: AppSupportRepository
    private let locationManager: LocationManager
    private let writeApiClient: CrisisCleanupWriteApi
    private let logger: AppLogger

    private let shareLock = NSLock()
    private var shareTimestamp = Date(timeIntervalSince1970: 0)
    private let shareInterval = 1.minutes

    // TODO: Remote config
    private let activeInterval = 4.hours

    init(
        accountDataRepository: AccountDataRepository,
        appPreferences: AppPreferencesDataSource,
        appSupportRepository: AppSupportRepository,
        locationManager: LocationManager,
        writeApiClient: CrisisCleanupWriteApi,
        loggerFactory: AppLoggerFactory
    ) {
        self.accountDataRepository = accountDataRepository
        self.appPreferences = appPreferences
        self.appSupportRepository = appSupportRepository
        self.locationManager = locationManager
        self.writeApiClient = writeApiClient
        logger = loggerFactory.getLogger("share-location")
    }

    func shareLocation() async {
        do {
            let preferences = try await appPreferences.preferences.eraseToAnyPublisher().asyncFirst()
            let shareLocationWithOrg = preferences.shareLocationWithOrg
            let accountData = try await accountDataRepository.accountData.eraseToAnyPublisher().asyncFirst()
            let areTokensValid = accountData.areTokensValid
            let metrics = try await appSupportRepository.appMetrics.eraseToAnyPublisher().asyncFirst()
            let lastAppOpen = metrics.openTimestamp
            let now = Date.now
            if shareLocationWithOrg,
               areTokensValid,
               lastAppOpen + activeInterval > now
            {
                if let location = locationManager.getLocation() {
                    let share = shareLock.withLock {
                        if shareTimestamp + shareInterval > now {
                            return false
                        }

                        shareTimestamp = now
                        return true
                    }

                    if share {
                        let coordinates = location.coordinate
                        try await writeApiClient.shareLocation(
                            latitude: coordinates.latitude,
                            longitude: coordinates.longitude
                        )
                    }
                }
            }
        } catch {
            logger.logError(error)
        }
    }
}
