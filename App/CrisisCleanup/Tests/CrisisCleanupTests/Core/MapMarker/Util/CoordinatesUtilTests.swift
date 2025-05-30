import XCTest
@testable import CrisisCleanup

final class CoordinatesUtilTests: XCTestCase {
    func testLongitude180Delta() {
        let coordinates = [
            (-180.0, 180.0),
            (0.0, 0.0),
            (-90, 90),
            (90, -90),
            (0, 180),
            (180, 0),
            (0, -180),
            (-180, 0),
        ]
        let expecteds = [
            -180,
             0.0,
             0.0,
             180,
             90,
             -90,
             90,
             -90,
        ]

        for i in expecteds.indices {
            let (left, right) = coordinates[i]
            let actual = CoordinatesUtil.getMiddleLongitude(left, right)
            XCTAssertEqual(expecteds[i], actual, accuracy: 1e-9)
        }
    }

    func testLongitudeGreaterHalfCircle() {
        let coordinates = [
            (-125.4, 54.7),
            (-56.3, 123.8),
            (-1, 179.1),
            (-179, 1.1),
        ]
        let expecteds = [
            144.65,
            -146.25,
            -90.95,
            91.05,
        ]

        for i in expecteds.indices {
            let (left, right) = coordinates[i]
            let actual = CoordinatesUtil.getMiddleLongitude(left, right)
            XCTAssertEqual(expecteds[i], actual, accuracy: 1e-9)
        }
    }

    func testLongitudeLesserHalfCircle() {
        let coordinates = [
            (-1, 178.9),
            (-178.8, 1.1),
            (-84.54803500, -81.24733000),
            (-81.24733000, -84.54803500),
            (-97.06846900, -96.87744100),
            (-96.87744100, -97.06846900),
        ]
        let expecteds = [
            88.95,
            -88.85,
            (-84.54803500 + -81.24733000) / 2,
            (-84.54803500 + -81.24733000) / 2,
            (-97.06846900 + -96.87744100) / 2,
            (-97.06846900 + -96.87744100) / 2,
        ]

        for i in expecteds.indices {
            let (left, right) = coordinates[i]
            let actual = CoordinatesUtil.getMiddleLongitude(left, right)
            XCTAssertEqual(expecteds[i], actual, accuracy: 1e-9)
        }
    }

    func testLongitudeCrossover() {
        let coordinates = [
            (170.0, -170.0),
            (165.4, -172.1),
            (177.7, -36.8),
            (177.7, -178.8),
            (170.0+360, -170.0),
            (165.4+360, -172.1),
            (177.7+360, -36.8),
            (177.7+360, -178.8),
            (170.0, -170.0-360),
            (165.4, -172.1-360),
            (177.7, -36.8-360),
            (177.7, -178.8-360),
        ]
        let expecteds = [
            180.0,
            176.65,
            -109.55,
            179.45,
            180.0,
            176.65,
            -109.55,
            179.45,
            180.0,
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
