import XCTest
@testable import CrisisCleanup

final class NetworkWorksitesSearchTests: XCTestCase {
    func testGetLocationSearchResult() throws {
        let result = Bundle(for: NetworkWorksitesSearchTests.self)
            .loadJson("worksiteLocationSearchResult", NetworkWorksiteLocationSearchResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(58, result.count)

        let actual = result.results?[1]
        let expected = NetworkWorksiteLocationSearch(
            incidentId: 255,
            id: 245758,
            address: "test address",
            caseNumber: "W10",
            city: "Fernandina Beach",
            county: "Nassau County",
            keyWorkType: NetworkWorkType(
                id: 1101893,
                createdAt: ISO8601DateFormatter().date(from: "2022-08-11T14:08:14Z"),
                orgClaim: nil,
                nextRecurAt: nil,
                phase: 4,
                recur: nil,
                status: "open_unassigned",
                workType: "tarp"
            ),
            location: NetworkLocation.LocationPoint(
                type: "Point",
                coordinates: [-82.9313994716109, 34.68370585735137]
            ),
            name: "test user",
            postalCode: "32034",
            state: "Florida"
        )
        XCTAssertEqual(expected, actual)
    }
}
