import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let logger: AppLogger

    @Published var viewData: MainViewData = MainViewData()

    @Published var isAuthenticated: Bool = false

    private var disposables = Set<AnyCancellable>()

    private var incidentsData: IncidentsData = LoadingIncidentsData

    init(
        accountDataRepository: AccountDataRepository,
        translationsRepository: LanguageTranslationsRepository,
        incidentSelector: IncidentSelector,
        syncPuller: SyncPuller,
        logger: AppLogger
    ) {
        self.accountDataRepository = accountDataRepository
        translator = translationsRepository
        self.syncPuller = syncPuller
        self.logger = logger

        incidentSelector.incidentsData
            .sink { data in
                self.incidentsData = data

                if !data.isEmpty {
                    self.sync(true)
                    syncPuller.appPullIncident(data.selectedId)
                    // TODO: Additional
                }
            }
            .store(in: &disposables)

        accountDataRepository.accountData
            .sink { accountData in
                self.viewData = MainViewData(
                    state: .ready,
                    accountData: accountData
                )

                if !accountData.isTokenInvalid {
                    self.sync(false)

                    let data = self.incidentsData
                    if !data.isEmpty {
                        syncPuller.appPullIncident(data.selectedId)
                    }
                }
            }
            .store(in: &disposables)

        syncPuller.pullUnauthenticatedData()
    }

    private func sync(_ cancelOngoing: Bool) {
        syncPuller.appPull(cancelOngoing)
    }
}
