import XCTest
@testable import CrisisCleanup

final class NetworkIncidentRedeployRequestTests: XCTestCase {
    func testRequestRedeploySuccessResult() throws {
        let result = Bundle(for: NetworkIncidentRedeployRequestTests.self)
            .loadJson("requestRedeploySuccess", NetworkIncidentRedeployRequest.self)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let expected = NetworkIncidentRedeployRequest(
            id: 23195,
            organization: 5430,
            incident: 280,
            createdAt: dateFormatter.date(from: "2024-03-06T21:00:34Z")!,
            organizationName: "Google Play Review",
            incidentName: "Madison County, AL Storm"
        )
        XCTAssertEqual(expected, result)
    }
}
