public protocol CrisisCleanupAccountApi {
    func initiateMagicLink(_ emailAddress: String) async -> Bool

    func initiatePhoneLogin(_ phoneNumber: String) async -> InitiatePhoneLoginResult

    func initiatePasswordReset(_ emailAddress: String) async throws -> InitiatePasswordResetResult

    func changePassword(
        password: String,
        token: String
    ) async -> Bool
}
