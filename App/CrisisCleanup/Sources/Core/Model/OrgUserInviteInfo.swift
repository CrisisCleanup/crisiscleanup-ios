import Foundation

public struct OrgUserInviteInfo: Equatable {
    let displayName: String
    let inviterEmail: String
    let inviterAvatarUrl: URL?
    let invitedEmail: String
    let orgName: String
    let isExpiredInvite: Bool
}

internal let ExpiredNetworkOrgInvite = OrgUserInviteInfo(
    displayName: "",
    inviterEmail: "",
    inviterAvatarUrl: nil,
    invitedEmail: "",
    orgName: "",
    isExpiredInvite: true
)
