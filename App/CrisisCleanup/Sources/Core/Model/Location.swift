public struct Location {
    let id: Int64
    let shapeLiteral: String
    // Should only be defined for Point and Polygon
    let coordinates: [Double]?
    // Should only be defined for MultiPolygon
    let multiCoordinates: [[Double]]?

    lazy var shape: LocationShape = { disasterFromLiteral(shapeLiteral) }()
}

enum LocationShape: String, Identifiable, CaseIterable {
    case unknown
    case point
    case polygon
    case multiPolygon

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
func disasterFromLiteral(_ literal: String) -> LocationShape { reverseLookup[literal] ?? LocationShape.unknown
}
