import Combine
import SwiftUI

class VolunteerOrgViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()

    init() { }

    func onViewAppear() { }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }
}
