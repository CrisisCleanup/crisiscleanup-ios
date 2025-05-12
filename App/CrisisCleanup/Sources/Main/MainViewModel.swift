import Combine
import SwiftUI

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let appSupportRepository: AppSupportRepository
    private let appVersionProvider: AppVersionProvider
    private let appPreferences: AppPreferencesDataSource
    private let incidentSelector: IncidentSelector
    private let appDataRepository: AppDataManagementRepository
    private let externalEventBus: ExternalEventBus
    private let accountEventBus: AccountEventBus
    private let router: NavigationRouter
    private let translationsRepository: LanguageTranslationsRepository
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let syncPusher: SyncPusher
    private let backgroundTaskCoordinator: BackgroundTaskCoordinator
    private let accountDataRefresher: AccountDataRefresher
    private let accountUpdateRepository: AccountUpdateRepository
    private let shareLocationRepository: ShareLocationRepository
    private let networkMonitor: NetworkMonitor
    private let logger: AppLogger

    @Published private(set) var viewData: MainViewData = MainViewData()
    private var isNotAuthenticated: Bool { !viewData.isAuthenticated }
    private var areTokensInvalid: Bool { !viewData.areTokensValid }

    let termsOfServiceUrl: URL
    let privacyPolicyUrl: URL
    private let isFetchingTermsAcceptanceSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isFetchingTermsAcceptance = false
    private let isUpdatingTermsAcceptanceSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private var isUpdatingTermsAcceptance = false
    @Published private(set) var isLoadingTermsAcceptance = false
    @Published private(set) var acceptTermsErrorMessage = ""

    @Published private(set) var minSupportedVersion = supportedAppVersion

    @Published var showAuthScreen = false

    @Published private(set) var showOnboarding = false

    @Published private(set) var showInactiveOrganization = false

    let isNotProduction: Bool

    private var incidentsData: IncidentsData = LoadingIncidentsData

    private var subscriptions = Set<AnyCancellable>()
    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        appSupportRepository: AppSupportRepository,
        appVersionProvider: AppVersionProvider,
        appPreferences: AppPreferencesDataSource,
        appSettingsProvider: AppSettingsProvider,
        translationsRepository: LanguageTranslationsRepository,
        incidentSelector: IncidentSelector,
        appDataRepository: AppDataManagementRepository,
        externalEventBus: ExternalEventBus,
        accountEventBus: AccountEventBus,
        navigationRouter: NavigationRouter,
        syncPuller: SyncPuller,
        syncPusher: SyncPusher,
        backgroundTaskCoordinator: BackgroundTaskCoordinator,
        accountDataRefresher: AccountDataRefresher,
        accountUpdateRepository: AccountUpdateRepository,
        shareLocationRepository: ShareLocationRepository,
        networkMonitor: NetworkMonitor,
        logger: AppLogger,
        appEnv: AppEnv
    ) {
        self.accountDataRepository = accountDataRepository
        self.appSupportRepository = appSupportRepository
        self.appVersionProvider = appVersionProvider
        self.appPreferences = appPreferences
        self.translationsRepository = translationsRepository
        translator = translationsRepository
        self.appDataRepository = appDataRepository
        self.incidentSelector = incidentSelector
        self.externalEventBus = externalEventBus
        self.accountEventBus = accountEventBus
        router = navigationRouter
        self.syncPuller = syncPuller
        self.syncPusher = syncPusher
        self.backgroundTaskCoordinator = backgroundTaskCoordinator
        self.accountDataRefresher = accountDataRefresher
        self.accountUpdateRepository = accountUpdateRepository
        self.shareLocationRepository = shareLocationRepository
        self.networkMonitor = networkMonitor
        self.logger = logger

        isNotProduction = appEnv.isNotProduction

        termsOfServiceUrl = appSettingsProvider.termsOfServiceUrl!
        privacyPolicyUrl = appSettingsProvider.privacyPolicyUrl!

        syncPuller.pullUnauthenticatedData()

        subscribeExternalEvent()
    }

    func onActivePhase() {
        translationsRepository.setLanguageFromSystem()
        appSupportRepository.onAppOpen()
        appSupportRepository.pullMinSupportedAppVersion()

        if viewData.isAuthenticated {
            syncPusher.scheduleSyncWorksites()
        }
    }

    func onBackgroundPhase() {
        backgroundTaskCoordinator.scheduleRefresh(secondsFromNow: 30 * 60)
        backgroundTaskCoordinator.schedulePushWorksites(secondsFromNow: 10 * 60)
    }

    func onViewAppear() {
        subscribeIncidentsData()
        subscribeAccountData()
        subscribeTermsAcceptanceState()
        subscribeAppSupport()
        subscribeAppPreferences()
        subscribeInactiveOrganization()

        shareLocationWithOrganization()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeExternalEvent() {
        externalEventBus.emailLoginLinks.sink { magicLinkCode in
            self.onEmailLoginLink(magicLinkCode)
        }
        .store(in: &disposables)

        externalEventBus.resetPasswords.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { resetCode in
                self.onResetPassword(resetCode)
            }
            .store(in: &disposables)

        externalEventBus.orgUserInvites.sink { inviteCode in
            self.onOrgUserInvite(inviteCode)
        }
        .store(in: &disposables)

        externalEventBus.orgPersistentInvites.sink { inviteInfo in
            self.onPersistentInvite(inviteInfo)
        }
        .store(in: &disposables)
    }

    private func subscribeIncidentsData() {
        incidentSelector.incidentId.eraseToAnyPublisher()
            .filter { $0 != EmptyIncident.id }
            .removeDuplicates()
            .sink { id in
                self.sync(
                    forcePullIncidents: false,
                    syncFullWorksites: true
                )
            }
            .store(in: &subscriptions)
    }

    private func subscribeAccountData() {
        let accountDataPublisher = accountDataRepository.accountData
            .eraseToAnyPublisher()
            .share()

        Publishers.CombineLatest3(
            accountDataPublisher,
            translator.translationCount.eraseToAnyPublisher(),
            $minSupportedVersion
        )
        .filter { (_, translationCount, _) in
            translationCount > 0
        }
        .map { (accountData, _, minSupport) in
            let isUnsupported = self.appVersionProvider.buildNumber < minSupport.minBuild
            return MainViewData(
                state: isUnsupported ? .unsupportedBuild : .ready,
                accountData: accountData
            )
        }
        .receive(on: RunLoop.main)
        .assign(to: \.viewData, on: self)
        .store(in: &subscriptions)

        accountDataPublisher
            .removeDuplicates()
            .sink { accountData in
                if accountData.areTokensValid {
                    self.sync(
                        forcePullIncidents: true,
                        syncFullWorksites: false
                    )

                    Task {
                        await self.accountDataRefresher.updateMyOrganization(true)
                        await self.accountDataRefresher.updateApprovedIncidents()
                    }

                    self.logger.setAccountId(String(accountData.id))
                } else {
                    if !accountData.hasAcceptedTerms {
                        self.accountEventBus.onLogout()
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeTermsAcceptanceState() {
        isFetchingTermsAcceptanceSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isFetchingTermsAcceptance, on: self)
            .store(in: &subscriptions)

        isUpdatingTermsAcceptanceSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isUpdatingTermsAcceptance, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $isFetchingTermsAcceptance,
            $isUpdatingTermsAcceptance
        )
        .map { b0, b1 in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isLoadingTermsAcceptance, on: self)
        .store(in: &subscriptions)

        accountDataRepository.accountData.eraseToAnyPublisher()
            .filter { !$0.hasAcceptedTerms }
            .removeDuplicates()
            .throttle(
                for: .seconds(0.25),
                scheduler: RunLoop.current,
                latest: true
            )
            .sink { data in
                self.isFetchingTermsAcceptanceSubject.value = true
                do {
                    defer {
                        self.isFetchingTermsAcceptanceSubject.value = false
                    }

                    await self.accountDataRefresher.updateAcceptedTerms()
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeAppSupport() {
        appSupportRepository.appMetrics
            .eraseToAnyPublisher()
            .map { $0.minSupportedVersion }
            .receive(on: RunLoop.main)
            .assign(to: \.minSupportedVersion, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeAppPreferences() {
        let preferencesPublisher = appPreferences.preferences.eraseToAnyPublisher()

        preferencesPublisher
            .map { !$0.hideOnboarding }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.showOnboarding, on: self)
            .store(in: &subscriptions)

        preferencesPublisher
            .map { $0.shareLocationWithOrg }
            .removeDuplicates()
            .sink {
                if $0 {
                    self.shareLocationWithOrganization()
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeInactiveOrganization() {
        accountEventBus.inactiveOrganizations
            .eraseToAnyPublisher()
            .throttle(
                for: .seconds(5),
                scheduler: RunLoop.current,
                latest: true
            )
            .filter { $0 > 0 }
            .receive(on: RunLoop.main)
            .sink { _ in
                self.showInactiveOrganization = true
                self.appDataRepository.clearAppData()
            }
            .store(in: &subscriptions)
    }

    private func sync(
        forcePullIncidents: Bool,
        syncFullWorksites: Bool
    ) {
        syncPuller.appPullIncidentData(
            cancelOngoing: false,
            forcePullIncidents: forcePullIncidents,
            cacheSelectedIncident: true,
            cacheActiveIncidentWorksites: false,
            cacheFullWorksites: syncFullWorksites,
            restartCacheCheckpoint: false
        )
    }

    func onRequireCheckAcceptTerms() {
        acceptTermsErrorMessage = translator.t("termsConditionsModal.must_check_box")
    }

    func onRejectTerms() {
        acceptTermsErrorMessage = ""
        accountEventBus.onLogout()
    }

    func onAcceptTerms() {
        acceptTermsErrorMessage = ""

        if isUpdatingTermsAcceptanceSubject.value {
            return
        }
        isUpdatingTermsAcceptanceSubject.value = true
        Task {
            do {
                defer {
                    isUpdatingTermsAcceptanceSubject.value = false
                }

                let isAccepted = await accountUpdateRepository.acceptTerms()
                if isAccepted {
                    await accountDataRefresher.updateAcceptedTerms()
                } else {
                    let errorMessage = try await networkMonitor.isOnline.eraseToAnyPublisher().asyncFirst()
                    ? translator.t("termsConditionsModal.online_but_error")
                    : translator.t("termsConditionsModal.offline_error")
                    Task { @MainActor in
                        acceptTermsErrorMessage = errorMessage
                    }
                }
            }
        }
    }

    func acknowledgeInactiveOrganization() {
        showInactiveOrganization = false
        accountEventBus.onLogout()
        accountEventBus.clearAccountInactiveOrganization()
    }

    private func onEmailLoginLink(_ code: String) {
        if areTokensInvalid {
            router.openMagicLinkLoginCode(code)
            showAuthScreen = true
        }
    }

    private func onResetPassword(_ code: String) {
        if code.isNotBlank {
            router.openResetPassword(code)
            showAuthScreen = true
        }
    }

    private func onOrgUserInvite(_ code: String) {
        if isNotAuthenticated,
           code.isNotBlank {
            router.openOrgUserInvite(code)
            showAuthScreen = true
        }
    }

    private func onPersistentInvite(_ inviteInfo: UserPersistentInvite) {
        if isNotAuthenticated,
           inviteInfo.inviteToken.isNotBlank {
            router.openOrgPersistentInvite(inviteInfo)
            showAuthScreen = true
        }
    }

    private func shareLocationWithOrganization() {
        Task {
            await shareLocationRepository.shareLocation()
        }
    }
}
