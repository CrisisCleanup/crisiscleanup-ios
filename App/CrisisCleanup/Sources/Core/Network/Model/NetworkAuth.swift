public struct NetworkAuthPayload: Codable {
    let email: String
    let password: String
}

public struct NetworkAuthUserClaims: Codable, Equatable {
    let id: Int64
    let email: String
    let firstName: String
    let lastName: String
    let files: [NetworkFile]?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case files
    }
}

public struct NetworkAuthOrganization: Codable, Equatable {
    let id: Int64
    let name: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isActive = "is_active"
    }
}

public struct NetworkAuthResult: Codable {
    let errors: [NetworkCrisisCleanupApiError]?
    let accessToken: String?
    let claims: NetworkAuthUserClaims?
    let organizations: NetworkAuthOrganization?

    enum CodingKeys: String, CodingKey {
        case errors
        case accessToken = "access_token"
        case claims = "user_claims"
        case organizations
    }
}
