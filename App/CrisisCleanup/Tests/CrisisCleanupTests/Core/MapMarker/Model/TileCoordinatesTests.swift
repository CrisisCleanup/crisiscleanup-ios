import XCTest
@testable import CrisisCleanup

final class TileCoordinatesTests: XCTestCase {
    func testCoordinatesToTileCoordinates() {
        let expectedLookup = [
            PairInt(70, -135): PairDouble(0.0, 0.7904007883569593),
            PairInt(70, -130): PairDouble(0.11111111111111112, 0.7904007883569593),
            PairInt(70, -125): PairDouble(0.22222222222222224, 0.7904007883569593),
            PairInt(70, -120): PairDouble(0.33333333333333337, 0.7904007883569593),
            PairInt(70, -115): PairDouble(0.4444444444444445, 0.7904007883569593),
            PairInt(70, -110): PairDouble(0.5555555555555556, 0.7904007883569593),
            PairInt(70, -105): PairDouble(0.6666666666666667, 0.7904007883569593),
            PairInt(70, -100): PairDouble(0.7777777777777778, 0.7904007883569593),
            PairInt(70, -95): PairDouble(0.888888888888889, 0.7904007883569593),
            PairInt(70, -90): PairDouble(1.0, 0.7904007883569593),
            PairInt(75, -135): PairDouble(0.0, 0.41839296767736744),
            PairInt(75, -130): PairDouble(0.11111111111111112, 0.41839296767736744),
            PairInt(75, -125): PairDouble(0.22222222222222224, 0.41839296767736744),
            PairInt(75, -120): PairDouble(0.33333333333333337, 0.41839296767736744),
            PairInt(75, -115): PairDouble(0.4444444444444445, 0.41839296767736744),
            PairInt(75, -110): PairDouble(0.5555555555555556, 0.41839296767736744),
            PairInt(75, -105): PairDouble(0.6666666666666667, 0.41839296767736744),
            PairInt(75, -100): PairDouble(0.7777777777777778, 0.41839296767736744),
            PairInt(75, -95): PairDouble(0.888888888888889, 0.41839296767736744),
            PairInt(75, -90): PairDouble(1.0, 0.41839296767736744),
        ]
        let tileCoordinates = TileCoordinates(x: 1, y: 1, zoom: 3)

        for lat in stride(from: -90, to: 90, by: 5) {
            for lng in stride(from: -180, to: 180, by: 5) {
                let n = tileCoordinates.fromLatLng(Double(lat), Double(lng))
                let expected = expectedLookup[PairInt(lat, lng)]
                XCTAssertEqual(expected, n == nil ? nil : PairDouble(n!.0, n!.1))
            }
        }
    }
}

private struct PairInt: Hashable {
    let a: Int
    let b: Int

    init(_ a: Int, _ b: Int) {
        self.a = a
        self.b = b
    }
}

private struct PairDouble: Equatable {
    let a: Double
    let b: Double

    init(_ a: Double, _ b: Double) {
        self.a = a
        self.b = b
    }

    public static func == (lhs: PairDouble, rhs: PairDouble) -> Bool {
        abs(lhs.a - rhs.a) < 1e-9 &&
        abs(lhs.b - rhs.b) < 1e-9
    }
}
