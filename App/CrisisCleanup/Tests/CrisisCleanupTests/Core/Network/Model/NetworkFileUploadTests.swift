import XCTest
@testable import CrisisCleanup

final class NetworkFileUploadTests: XCTestCase {
    func testStartUpload() throws {
        let result = Bundle(for: NetworkFileUploadTests.self)
            .loadJson("startFileUpload", NetworkFileUpload.self)

        let expected = NetworkFileUpload(
            id: 19,
            uploadProperties: FileUploadProperties(
                url: "https://crisiscleanup-user-files.s3.amazonaws.com/",
                fields: FileUploadFields(
                    key: "Screenshot 2023-05-22 at 9.08.00 AM-e409ec23517242eaad9eb58017e52702.png",
                    algorithm: "alg",
                    credential: "cred",
                    date: "date",
                    policy: "policy",
                    signature: "sig"
                )
            )
        )

        XCTAssertEqual(expected, result)
    }
}
