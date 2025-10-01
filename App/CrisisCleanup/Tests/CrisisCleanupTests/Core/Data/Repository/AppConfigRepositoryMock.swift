// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Combine
import Foundation
@testable import CrisisCleanup

public class AppConfigRepositoryMock: AppConfigRepository {
    public var appConfig: any Publisher<AppConfig, Never> {
        get { return Just(underlyingAppConfig) }
    }
    public var underlyingAppConfig = AppConfig()


    //MARK: - pullAppConfig

    public var pullAppConfigCallsCount = 0
    public var pullAppConfigCalled: Bool {
        return pullAppConfigCallsCount > 0
    }
    public var pullAppConfigClosure: (() async -> Void)?

    public func pullAppConfig() async {
        pullAppConfigCallsCount += 1
        await pullAppConfigClosure?()
    }
}
