import MapKit

class StaticMapCoordinator: NSObject, MKMapViewDelegate, TintCoordinator {
    var isTintApplied: Bool

    init(isTintApplied: Bool = true) {
        self.isTintApplied = isTintApplied
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        isTintApplied ? overlayMapRenderer(overlay as! MKPolygon) : BlankRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.staticMapAnnotationView(annotation, imageHeightOffsetWeight: -0.5)
    }
}
