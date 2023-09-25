import Combine
import SwiftUI

class AuthenticateViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let authEventBus: AuthEventBus

    @Published private(set) var viewData: AuthenticateViewData = AuthenticateViewData()

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        authEventBus: AuthEventBus
    ) {
        self.accountDataRepository = accountDataRepository
        self.authEventBus = authEventBus
    }

    func onViewAppear() {
        subscribeAccountData()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeAccountData() {
        accountDataRepository.accountData
            .eraseToAnyPublisher()
            .map {
                AuthenticateViewData(
                    state: .ready,
                    accountData: $0
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.viewData, on: self)
            .store(in: &subscriptions)
    }

    func logout() {
        authEventBus.onLogout()
    }
}
