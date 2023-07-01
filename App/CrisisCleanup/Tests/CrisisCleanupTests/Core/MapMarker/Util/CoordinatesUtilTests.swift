import XCTest
@testable import CrisisCleanup

final class CoordinatesUtilTests: XCTestCase {
    func testOrdered() {
        let coordinates = [
            (-180.0, 180.0),
            (0.0, 0.0),
            (-125.4, 10.6),
            (-25.54, 54.2),
        ]
        let expecteds = [
            0.0,
            0.0,
            -57.4,
            14.33,
        ]

        for i in expecteds.indices {
            let (left, right) = coordinates[i]
            let actual = CoordinatesUtil.getMiddleLongitude(left, right)
            XCTAssertEqual(expecteds[i], actual, accuracy: 1e-9)
        }
    }

    func testCrossover() {
        let coordinates = [
            (170.0, -170.0),
            (165.4, -2.1),
            (165.4, -172.1),
            (177.7, -36.8),
            (177.7, -178.8),
            (170.0+360, -170.0),
            (165.4+360, -2.1),
            (165.4+360, -172.1),
            (177.7+360, -36.8),
            (177.7+360, -178.8),
            (170.0, -170.0-360),
            (165.4, -2.1-360),
            (165.4, -172.1-360),
            (177.7, -36.8-360),
            (177.7, -178.8-360),
        ]
        let expecteds = [
            -180.0,
            -98.35,
            176.65,
            -109.55,
            179.45,
            -180.0,
            -98.35,
            176.65,
            -109.55,
            179.45,
            180.0,
            -98.35,
            176.65,
            -109.55,
            179.45,
        ]

        for i in expecteds.indices {
            let (left, right) = coordinates[i]
            let actual = CoordinatesUtil.getMiddleLongitude(left, right)
            XCTAssertEqual(expecteds[i], actual, accuracy: 1e-9)
        }
    }
}
