public struct NetworkLocationsResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkLocation]?
}

public struct NetworkLocation: Codable, Equatable {
    let id: Int64
    let geom: LocationGeometry?
    let poly: LocationPolygon?
    let point: LocationPoint?

    var shapeType: String { geom?.type ?? (poly?.type ?? (point?.type ?? "")) }

    public struct LocationGeometry: Codable, Equatable {
        let type: String
        let coordinates: [[[[Double]]]]

        // TODO: Test coverage
        var condensedCoordinates: [[Double]] { coordinates.map { $0[0].flatMap { $0 } } }
    }

    public struct LocationPolygon: Codable, Equatable {
        let type: String
        let coordinates: [[[Double]]]

        // TODO: Test coverage
        var condensedCoordinates: [Double] { coordinates[0].flatMap { $0 } }
    }

    public struct LocationPoint: Codable, Equatable {
        let type: String
        let coordinates: [Double]
    }

    internal static func flatten(_ coordinateSequence: [[Double]]) -> [Double] {
        var coordinates: [Double] = []
        for latLng in coordinateSequence {
            coordinates += latLng
        }
        return coordinates
    }
}
