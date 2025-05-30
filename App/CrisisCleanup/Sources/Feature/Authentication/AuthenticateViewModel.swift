import Combine
import SwiftUI

class AuthenticateViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository
    private let accountEventBus: AccountEventBus
    private let incidentsRepository: IncidentsRepository
    private let translator: KeyAssetTranslator

    let showRegister: Bool

    @Published private(set) var viewData = AuthenticateViewData()
    @Published private(set) var accountInfo = ""

    @Published private(set) var hotlineIncidents = [Incident]()

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        accountEventBus: AccountEventBus,
        incidentsRepository: IncidentsRepository,
        translator: KeyAssetTranslator
    ) {
        self.accountDataRepository = accountDataRepository
        self.accountEventBus = accountEventBus
        self.incidentsRepository = incidentsRepository
        self.translator = translator

        showRegister = false
    }

    func onViewAppear() {
        subscribeAccountData()
        subscribeIncidents()
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

        $viewData
            .filter { $0.state == .ready }
            .map {
                let account = $0.accountData
                return self.translator.t("info.account_is")
                    .replacingOccurrences(of: "{full_name}", with: account.fullName)
                    .replacingOccurrences(of: "{email_address}", with: account.emailAddress)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.accountInfo, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeIncidents() {
        $viewData
            .throttle(
                for: .seconds(60),
                scheduler: RunLoop.current,
                latest: true
            )
            .sink {
                if !$0.isAccountValid {
                    await self.incidentsRepository.pullHotlineIncidents()
                }
            }
            .store(in: &subscriptions)

        incidentsRepository.hotlineIncidents
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.hotlineIncidents, on: self)
            .store(in: &subscriptions)
    }

    func logout() {
        accountEventBus.onLogout()
    }
}
