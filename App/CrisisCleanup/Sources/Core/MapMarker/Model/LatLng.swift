import Atomics
import CoreLocation

public struct LatLng: Equatable {
    let latitude: Double
    let longitude: Double

    init(_ latitude: Double, _ longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension CLLocation {
    var latLng: LatLng { LatLng(coordinate.latitude, coordinate.longitude) }
}

let DefaultCoordinates = LatLng(40.272621, -96.012327)

// TODO Replace with actual location bounds from incident_id = 41762
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
        self.applyGuard = ManagedAtomic<Bool>(initialApply)
    }

    /**
     * @return true if bounds has yet to be taken (and applied to map) or false otherwise
     */
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
