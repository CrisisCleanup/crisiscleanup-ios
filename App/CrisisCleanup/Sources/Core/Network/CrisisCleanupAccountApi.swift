import Foundation

public protocol CrisisCleanupAccountApi {
    func initiateMagicLink(_ emailAddress: String) async -> Bool

    func initiatePhoneLogin(_ phoneNumber: String) async -> InitiatePhoneLoginResult

    func initiatePasswordReset(_ emailAddress: String) async throws -> InitiatePasswordResetResult

    func changePassword(
        password: String,
        token: String
    ) async -> Bool

    func acceptTerms(_ userId: Int64, _ timestamp: Date) async -> Bool
}

extension CrisisCleanupAccountApi {
    func acceptTerms(_ userId: Int64) async -> Bool {
        await acceptTerms(userId, Date.now)
    }
}
