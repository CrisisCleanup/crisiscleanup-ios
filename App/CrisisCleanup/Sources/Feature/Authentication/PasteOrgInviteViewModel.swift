import Combine
import Foundation

class PasteOrgInviteViewModel: ObservableObject {
    private let orgVolunteerRepository: OrgVolunteerRepository
    private let translator: KeyAssetTranslator

    private let isVerifyingCodeSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isVerifyingCode = false

    @Published private(set) var inviteCode = ""
    @Published private(set) var inviteCodeError = ""

    private let inviteCodeRegex = #/\/invitation_token\/([0-9a-f]+)$/#.ignoresCase()

    private var subscriptions = Set<AnyCancellable>()

    init(
        orgVolunteerRepository: OrgVolunteerRepository,
        translator: KeyAssetTranslator
    ) {
        self.orgVolunteerRepository = orgVolunteerRepository
        self.translator = translator
    }

    func onViewAppear() {
        subscribeViewState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeViewState() {
        isVerifyingCodeSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isVerifyingCode, on: self)
            .store(in: &subscriptions)
    }

    func onSubmitLink(_ link: String) {
        if link.isBlank {
            inviteCodeError = translator.t("volunteerOrg.paste_invitation_link")
            return
        }
        inviteCodeError = ""

        guard !isVerifyingCodeSubject.value else {
            return
        }
        isVerifyingCodeSubject.value = true
        Task {
            do {
                defer {
                    isVerifyingCodeSubject.value = false
                }

                var errorMessageKey = ""
                if let match = try? inviteCodeRegex.firstMatch(in: link.trim()) {
                    let code = String(match.output.1)
                    if let info = await orgVolunteerRepository.getInvitationInfo(code) {
                        if info.isExpiredInvite {
                            errorMessageKey = "pasteInvite.link_expired"
                        } else {
                            inviteCode = code
                        }
                    } else {
                        errorMessageKey = "pasteInvite.link_invalid"
                    }
                } else {
                    errorMessageKey = "pasteInvite.link_not_invitation"
                }

                if errorMessageKey.isNotBlank {
                    let translateKey = errorMessageKey
                    Task { @MainActor in
                        inviteCodeError = translator.t(translateKey)
                    }
                }
            }
        }
    }
}
