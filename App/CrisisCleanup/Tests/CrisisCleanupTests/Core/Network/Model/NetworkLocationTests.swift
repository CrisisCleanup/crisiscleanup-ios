import XCTest
@testable import CrisisCleanup

final class NetworkLocationTests: XCTestCase {
    func testGetLocationsSuccessResult() throws {
        let result = Bundle(for: NetworkLocationTests.self)
            .loadJson("getIncidentLocations", NetworkLocationsResult.self)

        XCTAssertNil(result.errors)
        XCTAssertEqual(3, result.count)

        let locations = result.results!
        XCTAssertEqual(
            ["Polygon", "MultiPolygon", "Point"],
            locations.map { $0.shapeType }
        )

        XCTAssertEqual(
            1074,
            locations[0].poly!.condensedCoordinates.count
        )

        let geoCoordinates = locations[1].geom!.condensedCoordinates
        XCTAssertEqual(6, geoCoordinates.count)
        XCTAssertEqual(
            [1582, 10, 16, 18, 26, 42],
            geoCoordinates.map { $0.count }
        )

        XCTAssertEqual(2, locations[2].point!.coordinates.count)
    }
}
