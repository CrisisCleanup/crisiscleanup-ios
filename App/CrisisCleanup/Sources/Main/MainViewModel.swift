import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let appSupportRepository: AppSupportRepository
    private let appVersionProvider: AppVersionProvider
    private let incidentSelector: IncidentSelector
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let accountDataRefresher: AccountDataRefresher
    private let logger: AppLogger

    @Published private(set) var viewData: MainViewData = MainViewData()

    @Published private(set) var minSupportedVersion = supportedAppVersion
    @Published private(set) var isBuildUnsupported = false

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
        self.accountDataRefresher = accountDataRefresher
        self.logger = logger

        isNotProduction = appEnv.isNotProduction

        syncPuller.pullUnauthenticatedData()
    }

    func onViewAppear() {
        appSupportRepository.onAppOpen()
        appSupportRepository.pullMinSupportedAppVersion()

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
        Publishers.CombineLatest(
            accountDataRepository.accountData.eraseToAnyPublisher(),
            translator.translationCount.eraseToAnyPublisher()
        )
        .filter { (_, translationCount) in
            translationCount > 0
        }
        .receive(on: RunLoop.main)
        .sink { (accountData, _) in
            self.viewData = MainViewData(
                state: .ready,
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

        $minSupportedVersion
            .map { self.appVersionProvider.buildNumber < $0.minBuild }
            .assign(to: \.isBuildUnsupported, on: self)
            .store(in: &subscriptions)
    }

    private func sync(_ cancelOngoing: Bool) {
        syncPuller.appPull(cancelOngoing)
    }
}
