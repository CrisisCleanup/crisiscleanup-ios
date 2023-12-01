import Combine
import CrisisCleanup
import Foundation

class CrisisCleanupExternalEventBus: ExternalEventBus {
    private let emailLoginLinksSubject = PassthroughSubject<String, Never>()
    let emailLoginLinks: any Publisher<String, Never>

    private let resetPasswordsSubject = PassthroughSubject<String, Never>()
    let resetPasswords: any Publisher<String, Never>

    private let orgUserInvitesSubject = PassthroughSubject<String, Never>()
    let orgUserInvites: any Publisher<String, Never>

    private let orgPersistentInvitesSubject = PassthroughSubject<UserPersistentInvite, Never>()
    let orgPersistentInvites: any Publisher<UserPersistentInvite, Never>

    init() {
        emailLoginLinks = emailLoginLinksSubject.share()
        resetPasswords = resetPasswordsSubject.share()
        orgUserInvites = orgUserInvitesSubject.share()
        orgPersistentInvites = orgPersistentInvitesSubject.share()
    }

    func onEmailLoginLink(_ code: String) {
        emailLoginLinksSubject.send(code)
    }

    func onResetPassword(_ code: String) {
        resetPasswordsSubject.send(code)
    }

    func onOrgUserInvite(_ code: String) {
        orgUserInvitesSubject.send(code)
    }

    func onOrgPersistentInvite(_ inviterUserId: Int64, _ inviteToken: String) {
        let invite = UserPersistentInvite(
            inviterUserId: inviterUserId,
            inviteToken: inviteToken
        )
        orgPersistentInvitesSubject.send(invite)
    }

    func onOrgPersistentInvite(_ query: [URLQueryItem]) -> Bool {
        if let inviterIdString = query.find("user-id"),
           let inviterId = Int64(inviterIdString),
           let token = query.find("invite-token") {
            onOrgPersistentInvite(inviterId, token)
            return true
        }
        return false
    }
}
