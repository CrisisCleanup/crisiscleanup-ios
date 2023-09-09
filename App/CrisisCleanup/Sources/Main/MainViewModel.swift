import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let appSupportRepository: AppSupportRepository
    private let appVersionProvider: AppVersionProvider
    private let incidentSelector: IncidentSelector
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let syncPusher: SyncPusher
    private let accountDataRefresher: AccountDataRefresher
    private let logger: AppLogger

    @Published private(set) var viewData: MainViewData = MainViewData()

    @Published private(set) var minSupportedVersion = supportedAppVersion

    let isNotProduction: Bool

    private var incidentsData: IncidentsData = LoadingIncidentsData

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        appSupportRepository: AppSupportRepository,
        appVersionProvider: AppVersionProvider,
        translationsRepository: LanguageTranslationsRepository,
        incidentSelector: IncidentSelector,
        syncPuller: SyncPuller,
        syncPusher: SyncPusher,
        accountDataRefresher: AccountDataRefresher,
        logger: AppLogger,
        appEnv: AppEnv
    ) {
        self.accountDataRepository = accountDataRepository
        self.appSupportRepository = appSupportRepository
        self.appVersionProvider = appVersionProvider
        translator = translationsRepository
        self.incidentSelector = incidentSelector
        self.syncPuller = syncPuller
        self.syncPusher = syncPusher
        self.accountDataRefresher = accountDataRefresher
        self.logger = logger

        isNotProduction = appEnv.isNotProduction

        syncPuller.pullUnauthenticatedData()
    }

    func onActivePhase() {
        appSupportRepository.onAppOpen()
        appSupportRepository.pullMinSupportedAppVersion()

        if viewData.isAuthenticated {
            syncPusher.scheduleSyncWorksites()
            syncPusher.scheduleSyncMedia()
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
        Publishers.CombineLatest3(
            accountDataRepository.accountData.eraseToAnyPublisher(),
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

        accountDataRepository.accountData
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

    private func sync(_ cancelOngoing: Bool) {
        syncPuller.appPull(cancelOngoing)
    }
}
