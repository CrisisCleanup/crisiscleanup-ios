// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
@testable import CrisisCleanup

class IncidentClaimThresholdDataSourceMock: IncidentClaimThresholdDataSource {
    //MARK: - saveIncidentThresholds

    var saveIncidentThresholdsThrowableError: Error?
    var saveIncidentThresholdsCallsCount = 0
    var saveIncidentThresholdsCalled: Bool {
        return saveIncidentThresholdsCallsCount > 0
    }
    var saveIncidentThresholdsReceivedArguments: (accountId: Int64, claimThresholds: [IncidentClaimThresholdRecord])?
    var saveIncidentThresholdsReceivedInvocations: [(accountId: Int64, claimThresholds: [IncidentClaimThresholdRecord])] = []
    var saveIncidentThresholdsClosure: ((Int64, [IncidentClaimThresholdRecord]) async throws -> Void)?

    func saveIncidentThresholds(_ accountId: Int64, _ claimThresholds: [IncidentClaimThresholdRecord]) async throws {
        if let error = saveIncidentThresholdsThrowableError {
            throw error
        }
        saveIncidentThresholdsCallsCount += 1
        saveIncidentThresholdsReceivedArguments = (accountId: accountId, claimThresholds: claimThresholds)
        saveIncidentThresholdsReceivedInvocations.append((accountId: accountId, claimThresholds: claimThresholds))
        try await saveIncidentThresholdsClosure?(accountId, claimThresholds)
    }

    //MARK: - getIncidentClaimThreshold

    var getIncidentClaimThresholdAccountIdIncidentIdThrowableError: Error?
    var getIncidentClaimThresholdAccountIdIncidentIdCallsCount = 0
    var getIncidentClaimThresholdAccountIdIncidentIdCalled: Bool {
        return getIncidentClaimThresholdAccountIdIncidentIdCallsCount > 0
    }
    var getIncidentClaimThresholdAccountIdIncidentIdReceivedArguments: (accountId: Int64, incidentId: Int64)?
    var getIncidentClaimThresholdAccountIdIncidentIdReceivedInvocations: [(accountId: Int64, incidentId: Int64)] = []
    var getIncidentClaimThresholdAccountIdIncidentIdReturnValue: IncidentClaimThreshold?
    var getIncidentClaimThresholdAccountIdIncidentIdClosure: ((Int64, Int64) throws -> IncidentClaimThreshold?)?

    func getIncidentClaimThreshold(accountId: Int64, incidentId: Int64) throws -> IncidentClaimThreshold? {
        if let error = getIncidentClaimThresholdAccountIdIncidentIdThrowableError {
            throw error
        }
        getIncidentClaimThresholdAccountIdIncidentIdCallsCount += 1
        getIncidentClaimThresholdAccountIdIncidentIdReceivedArguments = (accountId: accountId, incidentId: incidentId)
        getIncidentClaimThresholdAccountIdIncidentIdReceivedInvocations.append((accountId: accountId, incidentId: incidentId))
        if let getIncidentClaimThresholdAccountIdIncidentIdClosure = getIncidentClaimThresholdAccountIdIncidentIdClosure {
            return try getIncidentClaimThresholdAccountIdIncidentIdClosure(accountId, incidentId)
        } else {
            return getIncidentClaimThresholdAccountIdIncidentIdReturnValue
        }
    }
}
