import Foundation

public struct NetworkInvitationInfoResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let invite: NetworkInvitationInfo?
}

struct NetworkInvitationInfo: Codable, Equatable {
    let inviteeEmail: String
    let expiresAt: Date
    let organization: Int64
    let inviter: NetworkInviterInfo
    let existingUser: NetworkInviteeInfo?

    var isExistingUser: Bool {
        (existingUser?.id ?? 0) > 0
    }

    enum CodingKeys: String, CodingKey {
        case inviteeEmail = "invitee_email",
             expiresAt = "expires_at",
             organization,
             inviter = "invited_by",
             existingUser = "existing_user"
    }
}

struct NetworkInviterInfo: Codable, Equatable {
    let id: Int64
    let firstName: String
    let lastName: String
    let email: String
    let phone: String

    enum CodingKeys: String, CodingKey {
        case id,
             firstName = "first_name",
             lastName = "last_name",
             email,
             phone = "mobile"
    }
}

struct NetworkInviteeInfo: Codable, Equatable {
    let id: Int64
    let organization: Int64
}
