import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let incidentSelector: IncidentSelector
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let logger: AppLogger

    @Published var viewData: MainViewData = MainViewData()

    private var incidentsData: IncidentsData = LoadingIncidentsData

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        translationsRepository: LanguageTranslationsRepository,
        incidentSelector: IncidentSelector,
        syncPuller: SyncPuller,
        logger: AppLogger
    ) {
        self.accountDataRepository = accountDataRepository
        translator = translationsRepository
        self.incidentSelector = incidentSelector
        self.syncPuller = syncPuller
        self.logger = logger

        syncPuller.pullUnauthenticatedData()
    }

    func onViewAppear() {
        subscribeIncidentsData()
        subscribeAccountData()
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
                    // TODO: Additional
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribeAccountData() {
        accountDataRepository.accountData.eraseToAnyPublisher().combineLatest(
            self.translator.translationCount.eraseToAnyPublisher()
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

            if accountData.areTokensValid {
                self.sync(false)

                let data = self.incidentsData
                if !data.isEmpty {
                    self.syncPuller.appPullIncident(data.selectedId)
                }
            }
        }
        .store(in: &subscriptions)
    }

    private func sync(_ cancelOngoing: Bool) {
        syncPuller.appPull(cancelOngoing)
    }
}
