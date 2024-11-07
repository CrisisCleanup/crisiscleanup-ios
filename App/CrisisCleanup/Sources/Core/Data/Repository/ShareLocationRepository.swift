import Foundation

public protocol ShareLocationRepository {
    func shareLocation() async
}

class CrisisCleanupShareLocationRepository: ShareLocationRepository {
    private let accountDataRepository: AccountDataRepository
    private let appPreferences: AppPreferencesDataStore
    private let locationManager: LocationManager
    private let writeApiClient: CrisisCleanupWriteApi
    private let logger: AppLogger

    private let shareLock = NSLock()
    private var shareTimestamp = Date(timeIntervalSince1970: 0)
    private let shareInterval = 1.minutes

    init(
        accountDataRepository: AccountDataRepository,
        appPreferences: AppPreferencesDataStore,
        locationManager: LocationManager,
        writeApiClient: CrisisCleanupWriteApi,
        loggerFactory: AppLoggerFactory
    ) {
        self.accountDataRepository = accountDataRepository
        self.appPreferences = appPreferences
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
            if shareLocationWithOrg,
               areTokensValid
            {
                if let location = locationManager.getLocation() {
                    let share = shareLock.withLock {
                        let now = Date.now
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
