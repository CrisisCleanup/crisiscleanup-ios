// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
@testable import CrisisCleanup

public class AppLoggerMock: AppLogger {
    //MARK: - logDebug

    public var logDebugCallsCount = 0
    public var logDebugCalled: Bool {
        return logDebugCallsCount > 0
    }
    public var logDebugReceivedItems: Any?
    public var logDebugReceivedInvocations: [Any] = []
    public var logDebugClosure: ((Any) -> Void)?

    public func logDebug(_ items: Any...) {
        logDebugCallsCount += 1
        logDebugReceivedItems = items
        logDebugReceivedInvocations.append(items)
        logDebugClosure?(items)
    }

    //MARK: - logError

    public var logErrorCallsCount = 0
    public var logErrorCalled: Bool {
        return logErrorCallsCount > 0
    }
    public var logErrorReceivedE: Error?
    public var logErrorReceivedInvocations: [Error] = []
    public var logErrorClosure: ((Error) -> Void)?

    public func logError(_ e: Error) {
        logErrorCallsCount += 1
        logErrorReceivedE = e
        logErrorReceivedInvocations.append(e)
        logErrorClosure?(e)
    }

    //MARK: - logCapture

    public var logCaptureCallsCount = 0
    public var logCaptureCalled: Bool {
        return logCaptureCallsCount > 0
    }
    public var logCaptureReceivedMessage: String?
    public var logCaptureReceivedInvocations: [String] = []
    public var logCaptureClosure: ((String) -> Void)?

    public func logCapture(_ message: String) {
        logCaptureCallsCount += 1
        logCaptureReceivedMessage = message
        logCaptureReceivedInvocations.append(message)
        logCaptureClosure?(message)
    }

    //MARK: - setAccountId

    public var setAccountIdCallsCount = 0
    public var setAccountIdCalled: Bool {
        return setAccountIdCallsCount > 0
    }
    public var setAccountIdReceivedId: String?
    public var setAccountIdReceivedInvocations: [String] = []
    public var setAccountIdClosure: ((String) -> Void)?

    public func setAccountId(_ id: String) {
        setAccountIdCallsCount += 1
        setAccountIdReceivedId = id
        setAccountIdReceivedInvocations.append(id)
        setAccountIdClosure?(id)
    }
}
