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
