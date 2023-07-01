import Combine
import SwiftUI

class CasesFilterViewModel: ObservableObject {
    private let logger: AppLogger

    private var subscriptions = Set<AnyCancellable>()

    init(
        loggerFactory: AppLoggerFactory
    ) {
        logger = loggerFactory.getLogger("filter-cases")
    }

    func onViewAppear() {

    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }
}
