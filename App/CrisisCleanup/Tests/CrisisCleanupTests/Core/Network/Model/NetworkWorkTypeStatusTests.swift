import XCTest
@testable import CrisisCleanup

final class NetworkWorkTypeStatusTests: XCTestCase {
    func testGetLocationSearchResult() throws {
        let result = Bundle(for: NetworkWorkTypeStatusTests.self)
            .loadJson("getWorkTypeStatuses", NetworkWorkTypeStatusResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(15, result.count)

        let statuses = result.results
        XCTAssertNotNil(statuses)
        XCTAssertEqual(result.count, statuses?.count)
        let expectedStatusFirst = NetworkWorkTypeStatusFull(
            status: "open_unassigned",
            name: "Open, unassigned",
            listOrder: 10,
            primaryState: "open"
        )
        XCTAssertEqual(expectedStatusFirst, statuses![0])
        let expectedStatusLast = NetworkWorkTypeStatusFull(
            status: "open_partially-completed",
            name: "Open, partially completed",
            listOrder: 140,
            primaryState: "open"
        )
        XCTAssertEqual(expectedStatusLast, statuses![14])
    }
}
