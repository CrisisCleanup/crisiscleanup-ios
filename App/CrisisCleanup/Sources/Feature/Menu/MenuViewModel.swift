import Combine
import CoreLocation
import SwiftUI

class MenuViewModel: ObservableObject {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let accountDataRepository: AccountDataRepository
    private let accountDataRefresher: AccountDataRefresher
    private let incidentCacheRepository: IncidentCacheRepository
    private let dataDownloadSpeedMonitor: DataDownloadSpeedMonitor
    private let incidentSelector: IncidentSelector
    private let appVersionProvider: AppVersionProvider
    private let databaseVersionProvider: DatabaseVersionProvider
    private let appPreferences: AppPreferencesDataSource
    private let accountEventBus: AccountEventBus
    private let locationManager: LocationManager
    private let systemNotifier: SystemNotifier
    private let appEnv: AppEnv
    private let logger: AppLogger

    let isDebuggable: Bool
    let isProduction: Bool

    let termsOfServiceUrl: URL
    let privacyPolicyUrl: URL
    let gettingStartedVideoUrl: URL

    @Published private(set) var isLoadingIncidentData = true

    @Published private(set) var profilePicture: AccountProfilePicture? = nil

    @Published private(set) var incidentsData = LoadingIncidentsData
    @Published private(set) var hotlineIncidents = [Incident]()
    private var isHotlineIncidentsRefreshed = false

    @Published private(set) var menuItemVisibility = hideMenuItems

    @Published private(set) var shareLocationWithOrg = false
    @Published var showExplainLocationPermission = false
    @Published private(set) var hasLocationAccess = false

    @Published private(set) var incidentCachePreferences = InitialIncidentWorksitesCachePreferences
    @Published private(set) var incidentDataCacheMetrics = IncidentDataCacheMetrics()

    @Published private(set) var hasNotificationAccess = false

    var versionText: String {
        let version = appVersionProvider.version
        return "\(version.1) (\(version.0)) \(appEnv.apiEnvironment) iOS"
    }

    var databaseVersionText: String {
        isProduction ? "" : "DB \(databaseVersionProvider.databaseVersion)"
    }

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentsRepository: IncidentsRepository,
        worksitesRepository: WorksitesRepository,
        accountDataRepository: AccountDataRepository,
        accountDataRefresher: AccountDataRefresher,
        incidentCacheRepository: IncidentCacheRepository,
        dataDownloadSpeedMonitor: DataDownloadSpeedMonitor,
        syncLogRepository: SyncLogRepository,
        incidentSelector: IncidentSelector,
        appVersionProvider: AppVersionProvider,
        appSettingsProvider: AppSettingsProvider,
        databaseVersionProvider: DatabaseVersionProvider,
        appPreferences: AppPreferencesDataSource,
        accountEventBus: AccountEventBus,
        locationManager: LocationManager,
        systemNotifier: SystemNotifier,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.accountDataRepository = accountDataRepository
        self.accountDataRefresher = accountDataRefresher
        self.incidentCacheRepository = incidentCacheRepository
        self.dataDownloadSpeedMonitor = dataDownloadSpeedMonitor
        self.incidentSelector = incidentSelector
        self.appVersionProvider = appVersionProvider
        self.databaseVersionProvider = databaseVersionProvider
        self.appPreferences = appPreferences
        self.accountEventBus = accountEventBus
        self.locationManager = locationManager
        self.systemNotifier = systemNotifier
        self.appEnv = appEnv
        logger = loggerFactory.getLogger("menu")

        isDebuggable = appEnv.isDebuggable
        isProduction = appEnv.isProduction

        termsOfServiceUrl = appSettingsProvider.termsOfServiceUrl!
        privacyPolicyUrl = appSettingsProvider.privacyPolicyUrl!
        gettingStartedVideoUrl = appSettingsProvider.gettingStartedVideoUrl!

        hasLocationAccess = locationManager.hasLocationAccess

        Task {
            syncLogRepository.trimOldLogs()
        }
    }

    func onViewAppear() {
        Task {
            await accountDataRefresher.updateProfilePicture()
        }

        if !isHotlineIncidentsRefreshed {
            isHotlineIncidentsRefreshed = true
            Task {
                await self.incidentsRepository.pullHotlineIncidents()
            }
        }

        subscribeLoading()
        subscribeIncidentsData()
        subscribeProfilePicture()
        subscribeAppPreferences()
        subscribeLocationStatus()
        subscribeIncidentDataCacheState()
        subscribeNotificationStatus()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        incidentCacheRepository.isSyncingActiveIncident.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingIncidentData, on: self)
            .store(in: &subscriptions)

    }

    private func subscribeIncidentsData() {
        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)

        incidentsRepository.hotlineIncidents
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.hotlineIncidents, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeProfilePicture() {
        accountDataRepository.accountData
            .eraseToAnyPublisher()
            .compactMap {
                let pictureUrl = $0.profilePictureUri
                let isSvg = pictureUrl.hasSuffix(".svg")
                if let escapedUrl = isSvg ? pictureUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) : pictureUrl,
                   let url = URL(string: escapedUrl) {
                    return AccountProfilePicture(
                        url: url,
                        isSvg: isSvg
                    )
                }
                return nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.profilePicture, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeAppPreferences() {
        let appPreferencesPublisher = appPreferences.preferences.eraseToAnyPublisher()

        appPreferencesPublisher
            .map {
                return MenuItemVisibility(
                    showOnboarding: !$0.hideOnboarding,
                    showGettingStartedVideo: !$0.hideGettingStartedVideo
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.menuItemVisibility, on: self)
            .store(in: &subscriptions)

        appPreferencesPublisher
            .map { $0.shareLocationWithOrg }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.shareLocationWithOrg, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLocationStatus() {
        locationManager.$locationPermission
            .receive(on: RunLoop.main)
            .sink { _ in
                self.hasLocationAccess = self.locationManager.hasLocationAccess
            }
            .store(in: &subscriptions)
    }

    private func subscribeIncidentDataCacheState() {
        incidentCacheRepository.cachePreferences
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentCachePreferences, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $incidentCachePreferences,
            dataDownloadSpeedMonitor.isSlowSpeed
                .eraseToAnyPublisher()
                .removeDuplicates()
        )
        .map { (preferences, isSlow) in
            IncidentDataCacheMetrics(
                isSlow: isSlow,
                isPaused: preferences.isPaused,
                isRegionBound: preferences.isRegionBounded
            )
        }
        .receive(on: RunLoop.main)
        .assign(to: \.incidentDataCacheMetrics, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeNotificationStatus() {
        // Not observable
        Task {
            let hasAccess = await self.systemNotifier.isAuthorized()
            Task { @MainActor in
                self.hasNotificationAccess = hasAccess
            }
        }
    }

    func showGettingStartedVideo(_ show: Bool) {
        let hide = !show
        appPreferences.setHideGettingStartedVideo(hide)

        // TODO: Move to hide onboarding method when implemented
        appPreferences.setHideOnboarding(hide)
    }

    func useMyLocation() -> Bool {
        if locationManager.requestLocationAccess() {
            return true
        }

        if locationManager.isDeniedLocationAccess {
            showExplainLocationPermission = true
        }

        return false
    }


    func shareLocationWithOrg(_ share: Bool) {
        appPreferences.setShareLocationWithOrg(share)
    }

    func clearRefreshToken() {
        if isDebuggable {
            accountDataRepository.clearAccountTokens()
        }
    }

    func expireToken() {
        if isDebuggable {
            if let repository = accountDataRepository as? CrisisCleanupAccountDataRepository {
                repository.expireAccessToken()
            }
        }
    }
}

struct AccountProfilePicture {
    let url: URL
    let isSvg: Bool
}

struct MenuItemVisibility {
    let showOnboarding: Bool
    let showGettingStartedVideo: Bool
}
private let hideMenuItems = MenuItemVisibility(showOnboarding: false, showGettingStartedVideo: false)

struct IncidentDataCacheMetrics {
    let isSlow: Bool?
    let isPaused: Bool
    let isRegionBound: Bool

    let hasSpeedNotAdaptive: Bool

    init(
        isSlow: Bool? = nil,
        isPaused: Bool = false,
        isRegionBound: Bool = false
    ) {
        self.isSlow = isSlow
        self.isPaused = isPaused
        self.isRegionBound = isRegionBound

        hasSpeedNotAdaptive = isSlow == false && (isPaused || isRegionBound)
    }
}
