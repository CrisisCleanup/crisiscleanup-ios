import MapKit

public protocol MapViewContainer {
    var isSatelliteMapType: Bool { get }

}

public protocol TintCoordinator {
    var isTintApplied: Bool { get set }
}

extension MapViewContainer {
    func syncMapOverlays(_ map: MKMapView, _ mapOverlays: [MKOverlay]) {
        if var coordinator = (map.delegate as? TintCoordinator),
           coordinator.isTintApplied == isSatelliteMapType {
            // Overlays references don't match on first toggle
            let polygonOverlays = map.overlays.filter { $0 is MKPolygon }
            map.removeOverlays(polygonOverlays)

            coordinator.isTintApplied = !isSatelliteMapType
            if !isSatelliteMapType {
                map.addOverlays(mapOverlays)
            }
        }
    }
}
