import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

class LocationDaoTests: XCTestCase {
    func testLocationDao() async throws {
        let (_, appDb) = try initializeTestDb()
        let locationDao = LocationDao(appDb)

        let locationsA = [
            Location(
                id: 2,
                shapeLiteral: "shape-a",
                coordinates: [0.3, 5.1],
                multiCoordinates: nil
            ),
            Location(
                id: 3,
                shapeLiteral: "shape-b",
                coordinates: nil,
                multiCoordinates: [[55.32, -1.35], [65.456, -85.23]]
            ),
        ]
        try await locationDao.saveLocations(locationsA)

        let actual = locationDao.getLocations([2, 3])
        XCTAssertEqual(locationsA, actual)

        let locationsB = [
            Location(
                id: 2,
                shapeLiteral: "shape-a",
                coordinates: nil,
                multiCoordinates: [[78.22, -51.35], [0.456, -8.23]]
            ),
            Location(
                id: 3,
                shapeLiteral: "shape-b",
                coordinates: [56.3, -51.5],
                multiCoordinates: nil
            ),
        ]
        try await locationDao.saveLocations(locationsB)

        locationDao.streamLocations([3, 2])
            .collect(1)
            .expect([locationsB])
            .waitForExpectations(timeout: 0.1)
    }
}
