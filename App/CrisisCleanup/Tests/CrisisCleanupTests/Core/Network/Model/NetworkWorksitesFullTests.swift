import XCTest
@testable import CrisisCleanup

final class NetworkWorksitesFullTests: XCTestCase {
    func testGetWorksitesCount() throws {
        let result = Bundle(for: NetworkWorksitesFullTests.self)
            .loadJson("getWorksitesCountSuccess", NetworkCountResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(30, result.count)
    }

    func testGetWorksitesSuccessResult() throws {
        let result = Bundle(for: NetworkWorksitesFullTests.self)
            .loadJson("getWorksitesPagedSuccess", NetworkWorksitesFullResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(30, result.count)
    }

    func testGetWorksites2SuccessResult() throws {
        let result = Bundle(for: NetworkWorksitesFullTests.self)
            .loadJson("getWorksitesPaged2", NetworkWorksitesFullResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(30, result.count)
    }

    func testGetWorksitesResultFail() throws {
        let result = Bundle(for: NetworkWorksitesFullTests.self)
            .loadJson("expiredTokenResult", NetworkWorksitesFullResult.self)

        XCTAssertNil(result.count)
        XCTAssertNil(result.results)

        XCTAssertEqual(1, result.errors!.count)
        let firstError = result.errors![0]
        XCTAssertEqual(
            NetworkCrisisCleanupApiError(
                "detail",
                ["Token has expired."]
            ),
            firstError
        )
    }

    func testInvalidIncidentIdResponse() throws {
        let result = Bundle(for: NetworkWorksitesFullTests.self)
            .loadJson("worksitesInvalidIncidentResult", NetworkWorksitesFullResult.self)

        XCTAssertNil(result.count)
        XCTAssertNil(result.results)

        XCTAssertEqual(1, result.errors!.count)
        let firstError = result.errors![0]
        XCTAssertEqual(
            NetworkCrisisCleanupApiError(
                "incident",
                ["Select a valid choice. That choice is not one of the available choices."]
            ),
            firstError
        )
    }
}
