import XCTest
@testable import CrisisCleanup

final class NetworkWorksitesPageTests: XCTestCase {
    func testGetWorksitesSuccessResult() throws {
        let result = Bundle(for: NetworkWorksitesPageTests.self)
            .loadJson("worksitesPageSuccess", NetworkWorksitesPageResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(146, result.count)
        XCTAssertEqual(10, result.results?.count)

        // TODO: Compare entire result
        XCTAssertEqual(result.results![0].svi, 0.9616)
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
