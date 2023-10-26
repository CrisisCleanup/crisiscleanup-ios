import Combine
import Foundation

public protocol ExternalEventBus {
    var emailLoginLinks: any Publisher<String, Never> { get }
    var resetPasswords: any Publisher<String, Never> { get }
    var orgUserInvites: any Publisher<String, Never> { get }
    var orgPersistentInvites: any Publisher<String, Never> { get }

    func onEmailLoginLink(_ code: String)
    func onResetPassword(_ code: String)
    func onOrgUserInvite(_ code: String)
    func onOrgPersistentInvite(_ inviteToken: String)
}
