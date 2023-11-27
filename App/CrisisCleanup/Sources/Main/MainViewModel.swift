import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let appSupportRepository: AppSupportRepository
    private let appVersionProvider: AppVersionProvider
    private let incidentSelector: IncidentSelector
    private let externalEventBus: ExternalEventBus
    private let router: NavigationRouter
    private let translationsRepository: LanguageTranslationsRepository
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let syncPusher: SyncPusher
    private let accountDataRefresher: AccountDataRefresher
    private let logger: AppLogger

    @Published private(set) var viewData: MainViewData = MainViewData()
    private var isNotAuthenticated: Bool { !viewData.isAuthenticated }

    @Published private(set) var minSupportedVersion = supportedAppVersion

    @Published var showAuthScreen = false

    let isNotProduction: Bool

    private var incidentsData: IncidentsData = LoadingIncidentsData

    private var subscriptions = Set<AnyCancellable>()
    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        appSupportRepository: AppSupportRepository,
        appVersionProvider: AppVersionProvider,
        translationsRepository: LanguageTranslationsRepository,
        incidentSelector: IncidentSelector,
        externalEventBus: ExternalEventBus,
        navigationRouter: NavigationRouter,
        syncPuller: SyncPuller,
        syncPusher: SyncPusher,
        accountDataRefresher: AccountDataRefresher,
        logger: AppLogger,
        appEnv: AppEnv
    ) {
        self.accountDataRepository = accountDataRepository
        self.appSupportRepository = appSupportRepository
        self.appVersionProvider = appVersionProvider
        self.translationsRepository = translationsRepository
        translator = translationsRepository
        self.incidentSelector = incidentSelector
        self.externalEventBus = externalEventBus
        router = navigationRouter
        self.syncPuller = syncPuller
        self.syncPusher = syncPusher
        self.accountDataRefresher = accountDataRefresher
        self.logger = logger

        isNotProduction = appEnv.isNotProduction

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

    func onViewAppear() {
        subscribeIncidentsData()
        subscribeAccountData()
        subscribeAppSupport()
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
        incidentSelector.incidentsData
            .sink { data in
                self.incidentsData = data

                if !data.isEmpty {
                    self.sync(true)
                    self.syncPuller.appPullIncident(data.selectedId)
                }
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
        .receive(on: RunLoop.main)
        .sink { (accountData, _, minSupport) in
            let isUnsupported = self.appVersionProvider.buildNumber < minSupport.minBuild
            self.viewData =  MainViewData(
                state: isUnsupported ? .unsupportedBuild : .ready,
                accountData: accountData
            )
        }
        .store(in: &subscriptions)

        accountDataPublisher
            .sink { accountData in
                if accountData.areTokensValid {
                    self.sync(false)

                    let data = self.incidentsData
                    if !data.isEmpty {
                        self.syncPuller.appPullIncident(data.selectedId)
                    }

                    Task {
                        await self.accountDataRefresher.updateMyOrganization(true)
                    }
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

    private func onEmailLoginLink(_ code: String) {
        if isNotAuthenticated {
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

    private func sync(_ cancelOngoing: Bool) {
        syncPuller.appPull(cancelOngoing)
    }
}
