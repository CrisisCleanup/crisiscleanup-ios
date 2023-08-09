import Foundation
import XCTest
@testable import CrisisCleanup

class CoordinateGridQueryTests: XCTestCase {
    func testRadialDirectedOrdering() {
        let gridQuery = CoordinateGridQuery(SwNeBounds(
            south: 0.0,
            north: 0.0,
            west: 0.0,
            east: 0.0
        ))

        gridQuery.initializeGrid(9, targetGridSize: 10)
        XCTAssertEqual([(0, 0)], gridQuery.sortedCellCoordinates)

        gridQuery.initializeGrid(21, targetGridSize: 10)
        let expected2 = [
            (1, 1),
            (0, 1),
            (0, 0),
            (1, 0),
        ]
        XCTAssertEqual(expected2, gridQuery.sortedCellCoordinates)

        gridQuery.initializeGrid(240, targetGridSize: 10)
        XCTAssertEqual(21, gridQuery.sortedCellCoordinates.count)
        XCTAssertEqual(
            Set(gridQuery.sortedCellCoordinates.map { HashablePair($0) }).count,
            gridQuery.sortedCellCoordinates.count
        )
        let center = 2.5
        let radiiSqr5 = gridQuery.sortedCellCoordinates.map {
            pow(Double($0.0) + 0.5 - center, 2) + pow(Double($0.1) + 0.5 - center, 2)
        }
        for i in 1 ..< radiiSqr5.count {
            XCTAssertGreaterThanOrEqual(radiiSqr5[i], radiiSqr5[i - 1], "\(i)")
        }
    }
}

private struct HashablePair: Hashable {
    let a: Int
    let b: Int

    init(_ ab: (Int, Int)) {
        a = ab.0
        b = ab.1
    }
}
