import XCTest
@testable import CrisisCleanup

final class NetworkErrorTests: XCTestCase {
    func testDeserializeNetworkError() throws {
        let expecteds = [
            NetworkCrisisCleanupApiError("field", nil),
            NetworkCrisisCleanupApiError("field", nil),
            NetworkCrisisCleanupApiError("field", [""]),
            NetworkCrisisCleanupApiError("field", ["message"]),
            NetworkCrisisCleanupApiError("field", []),
            NetworkCrisisCleanupApiError("field", ["one"]),
            NetworkCrisisCleanupApiError("field", ["one", "two"]),
        ]
        let jsons = [
            #"{"field":"field"}"#,
            #"{"field":"field","message":null}"#,
            #"{"field":"field","message":""}"#,
            #"{"field":"field","message":"message"}"#,
            #"{"field":"field","message":[]}"#,
            #"{"field":"field","message":["one"]}"#,
            #"{"field":"field","message":["one","two"]}"#,
        ]
        let decoder = JsonDecoderFactory().decoder()
        for i in 0...(expecteds.count-1) {
            let expected = expecteds[i]
            let data = Data(jsons[i].utf8)
            let actual = try! decoder.decode(NetworkCrisisCleanupApiError.self, from: data)
            XCTAssertEqual(actual, expected)
        }
    }

    func testInvitationRequestError() throws {
        let errorString = #"{"errors": [{"field": "non_field_errors","message": ["It appears you already have an account."]}],"data": null}"#
        let decoder = JsonDecoderFactory().decoder()
        let data = Data(errorString.utf8)
        let actual = try! decoder.decode(NetworkAcceptedInvitationRequest.self, from: data)
        let expectedErrors = [NetworkCrisisCleanupApiError("non_field_errors", ["It appears you already have an account."])]
        XCTAssertEqual(actual.errors, expectedErrors)
        XCTAssertEqual(actual.errors?.condenseMessages, "It appears you already have an account.")
        XCTAssertNil(actual.id)
        XCTAssertNil(actual.requestedOrganization)
        XCTAssertNil(actual.requestedTo)
    }
}
