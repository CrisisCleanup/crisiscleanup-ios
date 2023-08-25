import SwiftUI
import Combine

class UserFeedbackViewModel: ObservableObject {
    private let accountDataRepository: AccountDataRepository

    private var subscriptions = Set<AnyCancellable>()

    @Published private(set) var isLoading: Bool = true

    @Published private(set) var accountId: Int64 = 0

    @Published private(set) var formHtmlPath: URL?

    private let formFileUrl: URL?

    init(
        accountDataRepository: AccountDataRepository
    ) {
        self.accountDataRepository = accountDataRepository

        if let htmlPath = Bundle.module.url(forResource: "user_feedback_form", withExtension: "html") {
            formFileUrl = htmlPath
        } else {
            formFileUrl = nil
        }
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeAccount()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        $accountId
            .receive(on: RunLoop.main)
            .sink(receiveValue: { id in
                if let fileUrl = self.formFileUrl {
                    self.formHtmlPath = fileUrl.appending(queryItems: [URLQueryItem(name: "accountCcid", value: String(id))])
                }
                self.isLoading = false
            })
            .store(in: &subscriptions)
    }

    private func subscribeAccount() {
        accountDataRepository.accountData
            .eraseToAnyPublisher()
            .map { $0.id }
            .receive(on: RunLoop.main)
            .assign(to: \.accountId, on: self)
            .store(in: &subscriptions)
    }
}
