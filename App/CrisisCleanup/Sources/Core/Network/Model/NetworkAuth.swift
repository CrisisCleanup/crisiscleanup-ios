public struct NetworkAuthPayload: Codable {
    let email: String
    let password: String
}

public struct NetworkAuthUserClaims: Codable, Equatable {
    let id: Int64
    let email: String
    let firstName: String
    let lastName: String
    let hasAcceptedTerms: Bool?
    let files: [NetworkFile]?
    let activeRoles: Set<Int>

    enum CodingKeys: String, CodingKey {
        case id,
             email,
             firstName = "first_name",
             lastName = "last_name",
             hasAcceptedTerms = "accepted_terms",
             files,
             activeRoles = "active_roles"
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

public struct NetworkOAuthPayload: Codable {
    let username: String
    let password: String
}

public struct NetworkRefreshToken: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

public struct NetworkOAuthResult: Codable {
    let error: String?
    let refreshToken: String?
    let accessToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case error,
             refreshToken = "refresh_token",
             accessToken = "access_token",
             expiresIn = "expires_in"
    }
}

public struct NetworkCodeAuthResult: Codable {
    let errors: [NetworkCrisisCleanupApiError]?
    let authTokens: NetworkOAuthTokens
}

public struct NetworkOAuthTokens: Codable {
    let refreshToken: String
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token",
             accessToken = "access_token",
             expiresIn = "expires_in"
    }
}
