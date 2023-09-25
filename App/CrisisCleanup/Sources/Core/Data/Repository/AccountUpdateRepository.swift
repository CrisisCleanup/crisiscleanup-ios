import Combine
import Foundation

public protocol AccountUpdateRepository {
    func initiateEmailMagicLink(_ emailAddress: String) async -> Bool
    func initiatePasswordReset(_ emailAddress: String) async -> PasswordResetInitiation
    func changePassword(password: String, token: String) async -> Bool
}

class CrisisCleanupAccountUpdateRepository: AccountUpdateRepository {
    func initiateEmailMagicLink(_ emailAddress: String) async -> Bool {
        // TODO: Do
        false
    }

    func initiatePasswordReset(_ emailAddress: String) async -> PasswordResetInitiation {
        // TODO: Do
        PasswordResetInitiation(nil)

    }

    func changePassword(password: String, token: String) async -> Bool {
        // TODO: Do
        false
    }

}

public struct PasswordResetInitiation {
    let expiresAt: Date?
    let errorMessage: String

    init(
        _ expiresAt: Date?,
        _ errorMessage: String = ""
    ) {
        self.expiresAt = expiresAt
        self.errorMessage = errorMessage
    }
}
