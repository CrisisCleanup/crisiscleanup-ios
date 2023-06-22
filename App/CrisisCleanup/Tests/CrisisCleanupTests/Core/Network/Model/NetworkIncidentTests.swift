import XCTest
@testable import CrisisCleanup

final class NetworkIncidentTests: XCTestCase {
    private let expectedIncidents = [
        fillNetworkIncident(
            158, "2019-09-25T00:00:00Z",
            "Small Tornado (Fake)", "chippewa_dunn_wi_tornado", "tornado",
            [NetworkIncidentLocation(129, 41905)]
        ),
        fillNetworkIncident(
            200, "2022-07-20T16:28:51Z",
            "Another Tornado (Fake)", "another_tornado", "tornado",
            [
                NetworkIncidentLocation(1, 73132),
                NetworkIncidentLocation(3, 73145)
            ]
        ),
        fillNetworkIncident(
            199, "2021-03-10T02:33:48Z",
            "Pandemic (Fake)", "covid_19_response", "virus",
            [NetworkIncidentLocation(2, 73141)]
        ),
        fillNetworkIncident(
            60, "2017-08-24T00:00:00Z",
            "Big Hurricane (Fake)", "hurricane_harvey", "hurricane",
            [NetworkIncidentLocation(63, 41823)],
            isArchived: true
        ),
        fillNetworkIncident(
            151, "2019-07-22T00:00:00Z",
            "Medium Storm (Fake)", "n_wi_derecho_jul_2019", "wind",
            [NetworkIncidentLocation(122, 41898)]
        )
    ]


    func testGetIncidentsSuccessResult() {
        let result = Bundle(for: NetworkIncidentTests.self)
            .loadJson("getIncidentsSuccess", NetworkIncidentsResult.self)

        XCTAssertNil(result.errors)

        XCTAssertEqual(5, result.count)

        let incidents = result.results!
        XCTAssertEqual(result.count, incidents.count)
        for (i, incident) in incidents.enumerated() {
            XCTAssertEqual(expectedIncidents[i], incident)
        }
        XCTAssertEqual(1658334531, incidents[1].startAt.timeIntervalSince1970)
    }

    func testGetIncidentsResultFail() {
        let result = Bundle(for: NetworkIncidentTests.self)
            .loadJson("expiredTokenResult", NetworkIncidentsResult.self)

        XCTAssertNil(result.count)
        XCTAssertNil(result.results)

        XCTAssertEqual(1, result.errors?.count)
        let firstError = result.errors?[0]
        XCTAssertEqual(
            NetworkCrisisCleanupApiError("detail", ["Token has expired."]),
            firstError
        )
    }
}
