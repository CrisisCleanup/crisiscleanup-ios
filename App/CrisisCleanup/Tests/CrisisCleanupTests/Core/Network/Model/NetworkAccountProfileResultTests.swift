import XCTest
@testable import CrisisCleanup

final class NetworkAccountProfileTests: XCTestCase {
    func testProfileAuthResult() throws {
        let account = Bundle(for: NetworkAccountProfileTests.self)
            .loadJson("getAccountProfileAuth", NetworkAccountProfileResult.self)

        XCTAssertEqual(Set([291]), account.approvedIncidents)
        XCTAssertEqual(true, account.hasAcceptedTerms)
        XCTAssertEqual(
            [NetworkFile(
                id: 920,
                blogUrl: "blog-image",
                createdAt: "2022-06-17T23:47:21.119619Z".toDate,
                file: 728,
                fileTypeT: "fileTypes.user_profile_picture",
                fullUrl: "full-url",
                largeThumbnailUrl: "large-thumbnail",
                mimeContentType: "image/png",
                notes: nil,
                smallThumbnailUrl: "small-thumbnail",
                tag: nil,
                title: nil,
                url: "url-file",
            )],
            account.files,
        )
        XCTAssertEqual(
            NetworkOrganizationShort(9, "Test org", true),
            account.organization,
        )
        XCTAssertEqual(Set([7]), account.activeRoles)
    }

    func testProfileNoAuthResult() throws {
        let account = Bundle(for: NetworkAccountProfileTests.self)
            .loadJson("getAccountProfileNoAuth", NetworkAccountProfileResult.self)

        XCTAssertNil(account.approvedIncidents)
        XCTAssertNil(account.hasAcceptedTerms)
        XCTAssertEqual(
            [NetworkFile(
                id: 920,
                blogUrl: "blog-image",
                createdAt: "2022-06-17T23:47:21.119619Z".toDate,
                file: 728,
                fileTypeT: "fileTypes.user_profile_picture",
                fullUrl: "full-url",
                largeThumbnailUrl: "large-thumbnail",
                mimeContentType: "image/png",
                notes: nil,
                smallThumbnailUrl: "small-thumbnail",
                tag: nil,
                title: nil,
                url: "url-file",
            )],
            account.files,
        )
        XCTAssertEqual(
            NetworkOrganizationShort(9, "", nil),
            account.organization,
        )
        XCTAssertNil(account.activeRoles)
    }
}
