import XCTest
@testable import CrisisCleanup

final class PolyUtilTests: XCTestCase {
    func testContainsLocation() {
        let actual = PolyUtil.containsLocation(
            LatLng(-77.0, 44.0),
            [
                LatLng(-81.0, 41.0),
                LatLng(-81.0, 47.0),
                LatLng(-72.0, 47.0),
                LatLng(-72.0, 41.0),
                LatLng(-81.0, 41.0),
            ]
        )
        XCTAssertTrue(actual)
    }
}
