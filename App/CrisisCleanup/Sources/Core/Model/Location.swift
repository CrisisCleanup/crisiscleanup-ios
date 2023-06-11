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
    case Unknown
    case Point
    case Polygon
    case MultiPolygon

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .Point: return "point"
        case .Polygon: return "polygon"
        case .MultiPolygon: return "multipolygon"
        default: return ""
        }
    }
}

fileprivate let reverseLookup = LocationShape.allCases.associateBy{ $0.literal }
func disasterFromLiteral(_ literal: String) -> LocationShape { reverseLookup[literal] ?? LocationShape.Unknown
}
