// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Combine
import Foundation
@testable import CrisisCleanup

class AccountInfoDataSourceMock: AccountInfoDataSource {
    var accountData: any Publisher<AccountData, Never> {
        get { return Just(underlyingAccountData) }
    }
    var underlyingAccountData = emptyAccountData

    //MARK: - setAccount

    var setAccountCallsCount = 0
    var setAccountCalled: Bool {
        return setAccountCallsCount > 0
    }
    var setAccountReceivedInfo: AccountInfo?
    var setAccountReceivedInvocations: [AccountInfo] = []
    var setAccountClosure: ((AccountInfo) -> Void)?

    func setAccount(_ info: AccountInfo) {
        setAccountCallsCount += 1
        setAccountReceivedInfo = info
        setAccountReceivedInvocations.append(info)
        setAccountClosure?(info)
    }

    //MARK: - clearAccount

    var clearAccountCallsCount = 0
    var clearAccountCalled: Bool {
        return clearAccountCallsCount > 0
    }
    var clearAccountClosure: (() -> Void)?

    func clearAccount() {
        clearAccountCallsCount += 1
        clearAccountClosure?()
    }

    //MARK: - updateExpiry

    var updateExpiryCallsCount = 0
    var updateExpiryCalled: Bool {
        return updateExpiryCallsCount > 0
    }
    var updateExpiryReceivedExpirySeconds: Int64?
    var updateExpiryReceivedInvocations: [Int64] = []
    var updateExpiryClosure: ((Int64) -> Void)?

    func updateExpiry(_ expirySeconds: Int64) {
        updateExpiryCallsCount += 1
        updateExpiryReceivedExpirySeconds = expirySeconds
        updateExpiryReceivedInvocations.append(expirySeconds)
        updateExpiryClosure?(expirySeconds)
    }

    //MARK: - expireAccessToken

    var expireAccessTokenCallsCount = 0
    var expireAccessTokenCalled: Bool {
        return expireAccessTokenCallsCount > 0
    }
    var expireAccessTokenClosure: (() -> Void)?

    func expireAccessToken() {
        expireAccessTokenCallsCount += 1
        expireAccessTokenClosure?()
    }

    //MARK: - update

    var updateCallsCount = 0
    var updateCalled: Bool {
        return updateCallsCount > 0
    }
    var updateReceivedArguments: (pictureUrl: String?, isAcceptedTerms: Bool, incidentIds: Set<Int64>, activeRoles: Set<Int>)?
    var updateReceivedInvocations: [(pictureUrl: String?, isAcceptedTerms: Bool, incidentIds: Set<Int64>, activeRoles: Set<Int>)] = []
    var updateClosure: ((String?, Bool, Set<Int64>, Set<Int>) -> Void)?

    func update(_ pictureUrl: String?, _ isAcceptedTerms: Bool, _ incidentIds: Set<Int64>, _ activeRoles: Set<Int>) {
        updateCallsCount += 1
        updateReceivedArguments = (pictureUrl: pictureUrl, isAcceptedTerms: isAcceptedTerms, incidentIds: incidentIds, activeRoles: activeRoles)
        updateReceivedInvocations.append((pictureUrl: pictureUrl, isAcceptedTerms: isAcceptedTerms, incidentIds: incidentIds, activeRoles: activeRoles))
        updateClosure?(pictureUrl, isAcceptedTerms, incidentIds, activeRoles)
    }
}
