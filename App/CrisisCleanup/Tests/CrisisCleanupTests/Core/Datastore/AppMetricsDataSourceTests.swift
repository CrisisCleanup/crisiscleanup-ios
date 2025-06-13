import Foundation
import XCTest
@testable import CrisisCleanup

class AppMetricsDataSourceTests: XCTestCase {
    private var dataSource: AppMetricsDataSource!

    override func setUp() async throws {
        dataSource = LocalAppMetricsDataSource()

        clearUserDefaults()
    }

    private func getMetrics() async throws -> AppMetrics {
        try await dataSource.metrics.eraseToAnyPublisher().asyncFirst()
    }

    func testAppOpen() async throws {
        let initial = try await getMetrics()

        XCTAssertEqual(initial.openBuild, 0)
        XCTAssertEqual(initial.openTimestamp, Date.epochZero)
        XCTAssertEqual(initial.installBuild, 0)

        let firstOpenTimestamp = dateNowRoundedSeconds.addingTimeInterval(-10.seconds)
        dataSource.setAppOpen(41, firstOpenTimestamp)

        let afterFirstOpen = try await getMetrics()
        XCTAssertEqual(afterFirstOpen.openBuild, 41)
        XCTAssertEqual(afterFirstOpen.openTimestamp, firstOpenTimestamp)
        XCTAssertEqual(afterFirstOpen.installBuild, 41)

        let secondOpenTimestamp = dateNowRoundedSeconds.addingTimeInterval(-3.seconds)
        dataSource.setAppOpen(56, secondOpenTimestamp)

        let afterSecondOpen = try await getMetrics()
        XCTAssertEqual(afterSecondOpen.openBuild, 56)
        XCTAssertEqual(afterSecondOpen.openTimestamp, secondOpenTimestamp)
        XCTAssertEqual(afterSecondOpen.installBuild, 41)
    }
}
