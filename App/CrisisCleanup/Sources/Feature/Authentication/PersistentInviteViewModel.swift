import Combine
import Foundation

class PersistentInviteViewModel: ObservableObject {
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator

    internal let inviteToken: String

    let editableViewState = EditableView()

    private var subscriptions = Set<AnyCancellable>()

    init(
        orgVolunteerRepository: OrgVolunteerRepository,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        inviteToken: String = ""
    ) {
        self.orgVolunteerRepository = orgVolunteerRepository
        self.inputValidator = inputValidator
        self.translator = translator

        self.inviteToken = inviteToken
    }

    func onViewAppear() {
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }
}
