// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
@testable import CrisisCleanup

public class WorksiteChangeDataProviderMock: WorksiteChangeDataProvider {
    public init() {}

    //MARK: - getOrgChanges

    public var getOrgChangesThrowableError: Error?
    public var getOrgChangesCallsCount = 0
    public var getOrgChangesCalled: Bool {
        return getOrgChangesCallsCount > 0
    }
    public var getOrgChangesReceivedOrgId: Int64?
    public var getOrgChangesReceivedInvocations: [Int64] = []
    public var getOrgChangesReturnValue: [WorksiteSerializedChange]!
    public var getOrgChangesClosure: ((Int64) throws -> [WorksiteSerializedChange])?

    public func getOrgChanges(_ orgId: Int64) throws -> [WorksiteSerializedChange] {
        if let error = getOrgChangesThrowableError {
            throw error
        }
        getOrgChangesCallsCount += 1
        getOrgChangesReceivedOrgId = orgId
        getOrgChangesReceivedInvocations.append(orgId)
        if let getOrgChangesClosure = getOrgChangesClosure {
            return try getOrgChangesClosure(orgId)
        } else {
            return getOrgChangesReturnValue
        }
    }

}
