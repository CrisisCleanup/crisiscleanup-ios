import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let logger: AppLogger

    @Published var viewData: MainViewData = MainViewData()

    private var disposables = Set<AnyCancellable>()

    @Published var isAuthenticated: Bool = false

    init(
        accountDataRepository: AccountDataRepository,
        logger: AppLogger
    ) {
        self.accountDataRepository = accountDataRepository
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
    }
}
