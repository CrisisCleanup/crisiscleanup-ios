struct NetworkInvitationRequest: Codable, Equatable {
    let firstName: String
    let lastName: String
    let email: String
    let title: String
    let password1: String
    let password2: String
    let mobile: String
    let requestedTo: String
    let primaryLanguage: Int64

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name",
             lastName = "last_name",
             email,
             title,
             password1,
             password2,
             mobile,
             requestedTo = "requested_to",
             primaryLanguage = "primary_language"
    }
}

public struct NetworkAcceptedInvitationRequest: Codable, Equatable {
    let id: Int64
    let requestedTo: String
    let requestedOrganization: String

    enum CodingKeys: String, CodingKey {
        case id,
             requestedTo = "requested_to",
             requestedOrganization = "requested_to_organization"
    }
}

struct NetworkAcceptCodeInvite: Codable, Equatable {
    let firstName: String
    let lastName: String
    let email: String
    let title: String
    let password: String
    let mobile: String
    let invitationToken: String
    let primaryLanguage: Int64

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name",
             lastName = "last_name",
             email,
             title,
             password,
             mobile,
             invitationToken = "invitation_token",
             primaryLanguage = "primary_language"
    }
}

struct NetworkAcceptPersistentInvite: Codable, Equatable {
    let firstName: String
    let lastName: String
    let email: String
    let title: String
    let password: String
    let mobile: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name",
             lastName = "last_name",
             email,
             title,
             password,
             mobile,
             token
    }
}

public struct NetworkAcceptedPersistentInvite: Codable, Equatable {
    let detail: String
}
