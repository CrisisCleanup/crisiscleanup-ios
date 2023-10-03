import Combine
import SwiftUI

class RequestOrgAccessViewModel: ObservableObject {

    @Published var emailAddress = ""

    @Published var languageOptions = [String]()

    @Published private(set) var isRequestingAccess = false

    let editableViewState = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init() {

    }

    func onViewAppear() {
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    func onVolunteerWithOrg() {
        // TODO: Do
    }
}
