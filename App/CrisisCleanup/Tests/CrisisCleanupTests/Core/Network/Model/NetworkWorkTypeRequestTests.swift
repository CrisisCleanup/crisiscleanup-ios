import XCTest
@testable import CrisisCleanup

final class NetworkWorkTypeRequestTests: XCTestCase {
    func testGetLocationsSuccessResult() throws {
        let result = Bundle(for: NetworkWorkTypeRequestTests.self)
            .loadJson("worksiteRequests", NetworkWorkTypeRequestResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(2, result.count)

        let dateFormatter = ISO8601DateFormatter()

        let workTypeRequests = result.results!
        XCTAssertEqual(result.count, workTypeRequests.count)
        let expected = NetworkWorkTypeRequest(
            id: 980,
            workType: NetworkWorkType(
                id: 1508174,
                createdAt: dateFormatter.date(from: "2023-04-14T17:56:17Z"),
                orgClaim: 4734,
                nextRecurAt: nil,
                phase: 4,
                recur: nil,
                status: "closed_no-help-wanted",
                workType: "trees"
            ),
            requestedBy: 31999,
            approvedAt: nil,
            rejectedAt: nil,
            tokenExpiration: dateFormatter.date(from: "2023-05-07T14:52:38Z")!,
            createdAt: dateFormatter.date(from: "2023-05-04T14:52:38Z")!,
            acceptedRejectedReason: nil,
            byOrg: NetworkOrganizationShort(89, "Crisis Cleanup Admin"),
            toOrg: NetworkOrganizationShort(4734, "test to org"),
            worksite: 252155
        )
        XCTAssertEqual(expected, workTypeRequests[0])
    }
}
