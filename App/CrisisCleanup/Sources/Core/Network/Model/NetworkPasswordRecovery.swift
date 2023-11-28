import Foundation

struct NetworkEmailPayload: Codable, Equatable {
    let email: String
}

struct NetworkMagicLinkResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
}

struct NetworkPhonePayload: Codable {
    let phone: String

    enum CodingKeys: String, CodingKey {
        case phone = "phone_number"
    }
}

struct NetworkPhoneCodeResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let message: String?
}

public struct InitiatePasswordResetResult: Codable, Equatable {
    let id: Int64
    let expiresAt: Date
    let isExpired: Bool
    let isValid: Bool
    let invalidMessage: String?

    enum CodingKeys: String, CodingKey {
        case id,
             expiresAt = "expires_at",
             isExpired = "is_expired",
             isValid = "is_valid",
             invalidMessage = "invalid_message"
    }
}

struct NetworkPasswordResetPayload: Codable, Equatable {
    let password: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case password,
             token = "password_reset_token"
    }
}

struct NetworkPasswordResetResult: Codable, Equatable {
    let status: String
}
