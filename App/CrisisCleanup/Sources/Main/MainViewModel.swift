import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    let translator: KeyAssetTranslator
    private let syncPuller: SyncPuller
    private let logger: AppLogger

    @Published var viewData: MainViewData = MainViewData()

    private var disposables = Set<AnyCancellable>()

    @Published var isAuthenticated: Bool = false

    init(
        accountDataRepository: AccountDataRepository,
        translationsRepository: LanguageTranslationsRepository,
        syncPuller: SyncPuller,
        logger: AppLogger
    ) {
        self.accountDataRepository = accountDataRepository
        translator = translationsRepository
        self.syncPuller = syncPuller
        self.logger = logger

        accountDataRepository.accountData
            .sink {
                let accountData = $0
                self.viewData = MainViewData(
                    state: .ready,
                    accountData: accountData
                )
            }
            .store(in: &disposables)

        accountDataRepository.accountData
            .filter { !$0.isTokenInvalid }
            .sink { data in
                self.sync(false)
            }
            .store(in: &disposables)

        syncPuller.pullUnauthenticatedData()
    }

    private func sync(_ force: Bool) {
        syncPuller.appPull(force)
    }
}
