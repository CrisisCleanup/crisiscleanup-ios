import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let logger: AppLogger

    @Published var viewData: MainViewData = MainViewData()

    private var disposables = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        logger: AppLogger
    ) {
        self.accountDataRepository = accountDataRepository
        self.logger = logger

        accountDataRepository.isAuthenticated
            .sink { b in
                self.viewData = MainViewData(
                    state: .ready,
                    isAuthenticated: b
                )
            }
            .store(in: &disposables)
    }
}
