import Combine
import Foundation

public protocol AccountUpdateRepository {
    func initiateEmailMagicLink(_ emailAddress: String) async -> Bool
    func initiatePasswordReset(_ emailAddress: String) async -> PasswordResetInitiation
    func changePassword(password: String, token: String) async -> Bool
}

class CrisisCleanupAccountUpdateRepository: AccountUpdateRepository {
    private let accountApi: CrisisCleanupAccountApi
    private let logger: AppLogger

    init(
        accountApi: CrisisCleanupAccountApi,
        loggerFactory: AppLoggerFactory
    ) {
        self.accountApi = accountApi
        logger = loggerFactory.getLogger("account")
    }

    func initiateEmailMagicLink(_ emailAddress: String) async -> Bool {
        await accountApi.initiateMagicLink(emailAddress)
    }

    func initiatePasswordReset(_ emailAddress: String) async -> PasswordResetInitiation {
        do {
            let result = try await accountApi.initiatePasswordReset(emailAddress)
            if result.isValid,
               result.expiresAt > Date.now {
                return PasswordResetInitiation(result.expiresAt, "")
            } else {
                if result.invalidMessage?.isNotBlank == true {
                    return PasswordResetInitiation(nil, result.invalidMessage!)
                }
            }
        } catch {
            logger.logError(error)
        }
        return PasswordResetInitiation(nil, "")
    }

    func changePassword(password: String, token: String) async -> Bool {
        await accountApi.changePassword(password: password, token: token)
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
