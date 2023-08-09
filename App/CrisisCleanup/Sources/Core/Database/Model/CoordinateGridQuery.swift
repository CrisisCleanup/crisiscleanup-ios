import Foundation

class CoordinateGridQuery {
    private let areaBounds: SwNeBounds

    private(set) var sortedCellCoordinates: [(Int, Int)] = []

    private var latitudeDelta: Double = 0.0
    private var longitudeDelta: Double = 0.0

    init(_ areaBounds: SwNeBounds) {
        self.areaBounds = areaBounds
    }

    func initializeGrid(
        _ totalCount: Int,
        targetGridSize: Int = 50
    ) {
        let approximateBucketCount = Double(totalCount) / Double(targetGridSize)
        let dimensionCount = max(Int(approximateBucketCount.squareRoot() + 1), 1)
        let ddDimensionCount = Double(dimensionCount)
        var cellCoordinates = [(Int, Int, Double)]()
        let gridCenter = ddDimensionCount * 0.5
        for i in 0 ..< dimensionCount {
            for j in 0 ..< dimensionCount {
                let radiusSqr = pow(gridCenter - (Double(i) + 0.5), 2) +
                pow(gridCenter - (Double(j) + 0.5), 2)
                cellCoordinates.append((i, j, radiusSqr))
            }
        }

        let centerSqr = pow(gridCenter, 2)
        sortedCellCoordinates = cellCoordinates
            .filter { $0.2 < centerSqr }
            .sorted(by: { a, b in
                let deltaRadiusSqr = abs(a.2 - b.2)
                if deltaRadiusSqr < 1e-5 {
                    let deltaX = a.0 - b.0
                    let deltaY = a.1 - b.1
                    let order = (deltaX >= 0 && deltaY > 0) ||
                    (deltaX >= 0 && deltaY == 0 && (Double(a.1) + 0.5) > gridCenter) ||
                    (deltaX < 0 && deltaY > 0) ||
                    (deltaX < 0 && deltaY == 0 && (Double(a.1) + 0.5) < gridCenter)
                    return order
                }
                if a.2 < b.2 { return true }
                return false
            })
            .map { ($0.0, $0.1) }

        latitudeDelta = (areaBounds.north - areaBounds.south) / ddDimensionCount
        longitudeDelta = (areaBounds.east - areaBounds.west) / ddDimensionCount
    }

    func getSwNeGridCells() -> [SwNeBounds] {
        sortedCellCoordinates.map { cellCoordinates in
            let south = areaBounds.south + Double(cellCoordinates.1) * latitudeDelta
            let north = south + latitudeDelta
            let west = areaBounds.west + Double(cellCoordinates.0) * longitudeDelta
            let east = west + longitudeDelta
            return SwNeBounds(
                south: south,
                north: north,
                west: west,
                east: east
            )
        }
    }
}
