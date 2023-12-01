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

struct NetworkPhoneCodePayload: Codable {
    let phone: String
    let code: String

    enum CodingKeys: String, CodingKey {
        case phone = "phone_number",
             code = "otp"
    }
}

struct NetworkPhoneOneTimePasswordResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let otpResult: NetworkOneTimePasswordResult
}

public struct NetworkOneTimePasswordResult: Codable, Equatable {
    let accounts: [OneTimePasswordPhoneAccount]
    let otpId: Int64

    enum CodingKeys: String, CodingKey {
        case accounts,
             otpId = "otp_id"
    }
}

struct OneTimePasswordPhoneAccount: Codable, Equatable {
    let id: Int64
    let email: String
    let organizationName: String

    enum CodingKeys: String, CodingKey {
        case id,
             email,
             organizationName = "organization"
    }
}

struct NetworkOneTimePasswordPayload: Codable {
    let accountId: Int64
    let otpId: Int64

    enum CodingKeys: String, CodingKey {
        case accountId = "user",
             otpId = "otp_id"
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
