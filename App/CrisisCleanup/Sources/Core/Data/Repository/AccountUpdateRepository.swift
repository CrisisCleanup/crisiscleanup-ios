import Combine
import Foundation

public protocol AccountUpdateRepository {
    func initiateEmailMagicLink(_ emailAddress: String) async -> Bool
    func initiatePhoneLogin(_ phoneNumber: String) async -> InitiatePhoneLoginResult
    func initiatePasswordReset(_ emailAddress: String) async -> PasswordResetInitiation
    func changePassword(password: String, token: String) async -> Bool
    func takeWasPasswordResetRecent() -> Bool
}

class CrisisCleanupAccountUpdateRepository: AccountUpdateRepository {
    private let accountApi: CrisisCleanupAccountApi
    private let logger: AppLogger

    private var passwordResetSuccessTime = Date.init(timeIntervalSince1970: 0)

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

    func initiatePhoneLogin(_ phoneNumber: String) async -> InitiatePhoneLoginResult {
        await accountApi.initiatePhoneLogin(phoneNumber)
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
        let isChanged = await accountApi.changePassword(password: password, token: token)
        if isChanged {
            passwordResetSuccessTime = Date.now
        }
        return isChanged
    }

    func takeWasPasswordResetRecent() -> Bool {
        let isRecent = passwordResetSuccessTime.distance(to: Date.now) < 30.minutes
        passwordResetSuccessTime = Date.init(timeIntervalSince1970: 0)
        return isRecent
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
