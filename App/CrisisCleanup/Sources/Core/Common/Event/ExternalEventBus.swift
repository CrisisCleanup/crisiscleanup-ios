import Combine
import Foundation

public protocol ExternalEventBus {
    var emailLoginLinks: any Publisher<String, Never> { get }
    var resetPasswords: any Publisher<String, Never> { get }
    var orgUserInvites: any Publisher<String, Never> { get }
    var orgPersistentInvites: any Publisher<UserPersistentInvite, Never> { get }

    func onEmailLoginLink(_ code: String)
    func onResetPassword(_ code: String)
    func onOrgUserInvite(_ code: String)
    func onOrgPersistentInvite(_ inviterUserId: Int64, _ inviteToken: String)
}

public struct UserPersistentInvite: Hashable, Codable {
    let inviterUserId: Int64
    let inviteToken: String

    public init(inviterUserId: Int64, inviteToken: String) {
        self.inviterUserId = inviterUserId
        self.inviteToken = inviteToken
    }
}
