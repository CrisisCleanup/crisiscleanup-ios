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
}
