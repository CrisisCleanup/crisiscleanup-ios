import Atomics
import CoreLocation

public struct LatLng: Equatable, CustomStringConvertible {
    public let latitude: Double
    public let longitude: Double

    public init(_ latitude: Double, _ longitude: Double) {
        self.latitude = max(-90.0, min(90.0, latitude))
        if longitude > -180,
           longitude <= 180 {
            self.longitude = longitude;
        } else {
            var l = longitude + 180.0
            l = l.truncatingRemainder(dividingBy: 360.0)
            if l <= 0 {
                l += 360
            }
            self.longitude = l - 180.0
        }
    }

    public var description: String { "lat/lng \(latitude)/\(longitude)" }

    public var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    public var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CLLocation {
    var latLng: LatLng { LatLng(coordinate.latitude, coordinate.longitude) }
}

extension CLLocationCoordinate2D {
    func approximatelyEquals(_ other: CLLocationCoordinate2D, tolerance: Double = 1e-5) -> Bool {
        abs(latitude - other.latitude) < tolerance &&
        abs(longitude - other.longitude) < tolerance
    }
}

private let defaultLat = 40.272621
private let defaultLng = -96.012327
let DefaultCoordinates = LatLng(defaultLat, defaultLng)
let DefaultCoordinates2d = CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng)

// TODO: Replace with actual location bounds from incident_id = 41762
let DefaultBounds = LatLngBounds(
    southWest: LatLng(28.598360630332458, -122.5307175747425),
    northEast: LatLng(47.27322983958189, -68.49771985492872)
)

public struct MapViewCameraBounds {
    let bounds: LatLngBounds
    let durationMs: Int

    private let initialApply: Bool

    private let applyGuard: ManagedAtomic<Bool>

    init(_ bounds: LatLngBounds,
         _ durationMs: Int = 500,
         _ initialApply: Bool = true
    ) {
        self.bounds = bounds
        self.durationMs = durationMs
        self.initialApply = initialApply
        self.applyGuard = ManagedAtomic(initialApply)
    }

    /// - Returns: true if bounds has yet to be taken (and applied to map) or false otherwise
    func takeApply() -> Bool { applyGuard.exchange(false, ordering: .acquiring) }
}

let MapViewCameraBoundsDefault = MapViewCameraBounds(
    LatLngBounds(
        southWest: DefaultBounds.southWest,
        northEast: DefaultBounds.northEast
    ),
    0,
    false
)
