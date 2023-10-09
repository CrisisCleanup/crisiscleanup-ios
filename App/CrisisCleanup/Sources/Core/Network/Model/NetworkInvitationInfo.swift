import Foundation

struct NetworkInvitationInfo: Codable, Equatable {
    let inviteeEmail: String
    let expiresAt: Date
    let organization: Int64
    let inviter: NetworkInviterInfo

    enum CodingKeys: String, CodingKey {
        case inviteeEmail = "invitee_email",
             expiresAt = "expires_at",
             organization,
             inviter = "invited_by"
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
