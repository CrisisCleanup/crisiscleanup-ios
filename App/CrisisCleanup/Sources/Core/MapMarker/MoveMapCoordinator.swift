import MapKit

class MoveMapCoordinator: NSObject, MKMapViewDelegate, TintCoordinator {
    let regionChangeListener: MapViewRegionChangeListener

    var isTintApplied: Bool = false

    internal lazy var animationManager = {
        CircleAnimationManager()
    }()

    init(
        regionChangeListener: MapViewRegionChangeListener,
        isTintApplied: Bool = true,
    ) {
        self.regionChangeListener = regionChangeListener
        self.isTintApplied = isTintApplied
    }

    private func regionDidChangeFromUserInteraction(
        _ mapView: MKMapView,
        gestureState: UIGestureRecognizer.State
    ) -> Bool {
        mapView.subviews
            .compactMap { $0.gestureRecognizers }
            .reduce([], +)
            .contains { $0.state == gestureState }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let overlay as MKPolygon:
            return isTintApplied ? overlayMapRenderer(overlay) : BlankRenderer(overlay: overlay)
        case let overlay as AnimatedCircleOverlay:
            let renderer = AnimatedCircleRenderer(
                overlay,
                fillColor: UIColor(appTheme.colors.primaryOrangeColor.disabledAlpha()),
                strokeColor: UIColor(appTheme.colors.primaryOrangeColor),
                lineWidth: 5
            )

            animationManager.circle = overlay
            animationManager.renderer = renderer

            return renderer
        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.reusableAnnotationView(annotation)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let isUserAction = regionDidChangeFromUserInteraction(mapView, gestureState: .ended)
        regionChangeListener.onRegionChange(
            mapView.centerCoordinate,
            isUserAction: isUserAction,
            isMapMoving: animated
        )
    }
}
