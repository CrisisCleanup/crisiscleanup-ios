import XCTest
@testable import CrisisCleanup

final class NetworkWorksitesPageTests: XCTestCase {
    func testWorksitesPageDate() {
        let formatter = WorksitesPageDateFormatter().formatter

        let expectedDate = Date(timeIntervalSince1970: 1683140180505.0 / 1000.0)

        let dateString = "2023-05-03T18:56:20.505769+00:00"
        let date = formatter.date(from: dateString)
        XCTAssertEqual(date, expectedDate)
    }

    func testGetWorksitesSuccessResult() throws {
        let result = Bundle(for: NetworkWorksitesPageTests.self)
            .loadJson("worksitesPageSuccess", NetworkWorksitesPageResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(146, result.count)
        XCTAssertEqual(10, result.results?.count)
    }

    func testGetWorksitesResultFail() throws {
        let result = Bundle(for: NetworkWorksitesPageTests.self)
            .loadJson("expiredTokenResult", NetworkWorksitesPageResult.self)

        XCTAssertNil(result.count)
        XCTAssertNil(result.results)

        XCTAssertEqual(1, result.errors?.count)
        let firstError = result.errors![0]
        XCTAssertEqual(
            NetworkCrisisCleanupApiError(
                "detail",
                ["Token has expired."]
            ),
            firstError
        )
    }
}
