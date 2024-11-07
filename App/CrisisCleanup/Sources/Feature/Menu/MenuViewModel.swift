import Combine
import SwiftUI

class MenuViewModel: ObservableObject {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let accountDataRepository: AccountDataRepository
    private let accountDataRefresher: AccountDataRefresher
    private let incidentSelector: IncidentSelector
    private let appVersionProvider: AppVersionProvider
    private let databaseVersionProvider: DatabaseVersionProvider
    private let appPreferences: AppPreferencesDataStore
    private let accountEventBus: AccountEventBus
    private let appEnv: AppEnv
    private let logger: AppLogger

    let isDebuggable: Bool
    let isProduction: Bool

    let termsOfServiceUrl: URL
    let privacyPolicyUrl: URL
    let gettingStartedVideoUrl: URL

    @Published private(set) var isLoadingIncidents = true
    @Published private(set) var showHeaderLoading = false

    @Published private(set) var profilePicture: AccountProfilePicture? = nil

    @Published private(set) var incidentsData = LoadingIncidentsData
    @Published private(set) var hotlineIncidents = [Incident]()

    @Published private(set) var menuItemVisibility = hideMenuItems

    @Published private(set) var shareLocationWithOrg = false

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
        syncLogRepository: SyncLogRepository,
        incidentSelector: IncidentSelector,
        appVersionProvider: AppVersionProvider,
        appSettingsProvider: AppSettingsProvider,
        databaseVersionProvider: DatabaseVersionProvider,
        appPreferences: AppPreferencesDataStore,
        accountEventBus: AccountEventBus,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.accountDataRepository = accountDataRepository
        self.accountDataRefresher = accountDataRefresher
        self.incidentSelector = incidentSelector
        self.appVersionProvider = appVersionProvider
        self.databaseVersionProvider = databaseVersionProvider
        self.appPreferences = appPreferences
        self.accountEventBus = accountEventBus
        self.appEnv = appEnv
        logger = loggerFactory.getLogger("menu")

        isDebuggable = appEnv.isDebuggable
        isProduction = appEnv.isProduction

        termsOfServiceUrl = appSettingsProvider.termsOfServiceUrl!
        privacyPolicyUrl = appSettingsProvider.privacyPolicyUrl!
        gettingStartedVideoUrl = appSettingsProvider.gettingStartedVideoUrl!

        Task {
            syncLogRepository.trimOldLogs()
        }
    }

    func onViewAppear() {
        Task {
            await accountDataRefresher.updateProfilePicture()
        }

        subscribeLoading()
        subscribeIncidentsData()
        subscribeProfilePicture()
        subscribeAppPreferences()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        let incidentsLoading = incidentsRepository.isLoading.eraseToAnyPublisher().share()

        incidentsLoading
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingIncidents, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            incidentsLoading,
            worksitesRepository.isLoading.eraseToAnyPublisher()
        )
        .map { b0, b1 in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.showHeaderLoading, on: self)
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

    func showGettingStartedVideo(_ show: Bool) {
        let hide = !show
        appPreferences.setHideGettingStartedVideo(hide)

        // TODO: Move to hide onboarding method when implemented
        appPreferences.setHideOnboarding(hide)
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
