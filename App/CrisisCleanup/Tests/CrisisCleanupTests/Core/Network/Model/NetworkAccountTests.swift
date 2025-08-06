import XCTest
@testable import CrisisCleanup

final class NetworkAccountTests: XCTestCase {
    func testUserMeResult() throws {
        let account = Bundle(for: NetworkAccountTests.self)
            .loadJson("accountResponseSuccess", NetworkUserProfile.self)

        XCTAssertEqual(18602, account.id)
        XCTAssertEqual("demo@crisiscleanup.org", account.email)
        XCTAssertEqual("Demo", account.firstName)
        XCTAssertEqual("User", account.lastName)
        XCTAssertEqual(Set([Int64(153), 5, 1]), account.approvedIncidents)

        let files = account.files
        XCTAssertEqual(1, files!.count)
        let expectedFile = NetworkFile(
            id: 5,
            blogUrl: "blog-url",
            createdAt: "2023-06-28T16:23:26Z".toDate,
            file: 87278,
            fileTypeT: "fileTypes.user_profile_picture",
            fullUrl: "full-url",
            largeThumbnailUrl: "large-thumbnail",
            mimeContentType: "image/jpeg",
            notes: nil,
            smallThumbnailUrl: "small-thumbnail",
            tag: nil,
            title: nil,
            url: "https://crisiscleanup-user-files.s3.amazonaws.com/6645713-b99b0bfba6a04d24879b35538d1c8b9f.jpg?AWSAccessKeyId=AKIASU3RMDS2EGFBJH5O&Signature=Ez3PS71Gedweed%2BWZLT0rF%2BU9AY%3D&Expires=1673376442",
        )
        let firstFile = files![0]
        XCTAssertEqual(
            expectedFile, firstFile
        )

        let expectedOrganization = NetworkOrganizationShort(
            12,
            "Demo Recovery Organization",
            true,
        )
        XCTAssertEqual(account.organization, expectedOrganization)
    }
}
