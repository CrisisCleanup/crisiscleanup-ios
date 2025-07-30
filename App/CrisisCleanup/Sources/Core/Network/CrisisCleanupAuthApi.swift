public protocol CrisisCleanupAuthApi {
    func oauthLogin(_ email: String, _ password: String) async throws -> NetworkOAuthResult?

    func magicLinkLogin(_ token: String) async throws -> NetworkOAuthTokens?

    func verifyPhoneCode(phoneNumber: String, code: String) async -> NetworkOneTimePasswordResult?

    func oneTimePasswordLogin(accountId: Int64, oneTimePasswordId: Int64) async throws -> NetworkOAuthTokens?

    func refreshTokens(_ refreshToken: String) async throws -> NetworkOAuthResult?
}
