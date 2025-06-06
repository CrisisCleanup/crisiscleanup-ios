import CoreLocation

public struct Location: Equatable {
    let id: Int64
    let shapeLiteral: String
    // Should only be defined for Point and Polygon
    let coordinates: [Double]?
    // Should only be defined for MultiPolygon
    let multiCoordinates: [[Double]]?

    let shape: LocationShape

    init(
        id: Int64,
        shapeLiteral: String,
        coordinates: [Double]?,
        multiCoordinates: [[Double]]?
    ) {
        self.id = id
        self.shapeLiteral = shapeLiteral
        self.coordinates = coordinates
        self.multiCoordinates = multiCoordinates
        shape = disasterFromLiteral(shapeLiteral)
    }
}

enum LocationShape: String, Identifiable, CaseIterable {
    case unknown,
         point,
         polygon,
         multiPolygon

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .point: return "point"
        case .polygon: return "polygon"
        case .multiPolygon: return "multipolygon"
        default: return ""
        }
    }
}

private let reverseLookup = LocationShape.allCases.associateBy{ $0.literal }
func disasterFromLiteral(_ literal: String) -> LocationShape {
    reverseLookup[literal] ?? LocationShape.unknown
}

protocol IncidentLocationBounder {
    func isInBounds(
        _ incidentId: Int64,
        latitude: Double,
        longitude: Double,
    ) async -> Bool

    func getBoundsCenter(_ incidentId: Int64) async -> CLLocation?
}
