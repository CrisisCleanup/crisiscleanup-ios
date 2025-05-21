import CoreLocation
import MapKit
import SwiftUI

class MoveOnMapCoordinator: NSObject, MKMapViewDelegate {
    let mapCenterMover: MapCenterMover

    private var hasInteracted = false

    fileprivate let animationManager = CircleAnimationManager()

    init(mapCenterMover: MapCenterMover) {
        self.mapCenterMover = mapCenterMover
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
            return overlayMapRenderer(overlay)
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
        mapCenterMover.onMapMove(
            mapView.centerCoordinate,
            isUserAction: isUserAction,
            isMapMoving: animated
        )
    }
}

struct MoveOnMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var targetCoordinates: CLLocationCoordinate2D
    @Binding var isPinCenterScreen: Bool
    @Binding var isTargetOutOfBounds: Bool
    @Binding var boundingRadius: Double

    var mapCenterMover: MapCenterMover
    var isScrollEnabled: Bool = true

    private func makeAnnotation(imageName: String, id: String) -> CustomPinAnnotation {
        let image = UIImage(named: imageName, in: .module, with: .none)!
        return CustomPinAnnotation(
            targetCoordinates,
            image: image,
            id: id,
        )
    }

    func makeUIView(context: Context) -> MKMapView {
        let isNewMap = map.annotations.isEmpty

        map.configure(
            isScrollEnabled: isScrollEnabled,
            isExistingMap: !isNewMap,
        )

        map.delegate = context.coordinator

        if isNewMap {
            let annotation = makeAnnotation(imageName: "cc_map_pin", id: "in-bounds")
            map.addAnnotation(annotation)
            map.showAnnotations([annotation], animated: false)
        }

        return map
    }

    func makeCoordinator() -> MoveOnMapCoordinator {
        MoveOnMapCoordinator(mapCenterMover: mapCenterMover)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MoveOnMapView>) {
        uiView.isScrollEnabled = isScrollEnabled

        updateCircleOverlay(
            uiView,
            context.coordinator,
            boundingRadius.milesToMeters,
            targetCoordinates,
        )

        if let annotation = uiView.annotations.first(where: { $0 is CustomPinAnnotation }),
           var customAnnotation = annotation as? CustomPinAnnotation {
            let expectedId = isTargetOutOfBounds ? "out-of-bounds" : "in-bounds"
            if customAnnotation.id != expectedId {
                uiView.removeAnnotation(customAnnotation)
                let imageName = isTargetOutOfBounds ? "cc_map_pin_oob" : "cc_map_pin"
                customAnnotation = makeAnnotation(imageName: imageName, id: expectedId)
                // TODO: Animate from removed coordinate to target coordinate
                uiView.addAnnotation(customAnnotation)
            }

            if isPinCenterScreen {
                UIView.animate(withDuration: 0.3) {
                    customAnnotation.coordinate = targetCoordinates
                }
            } else {
                customAnnotation.coordinate = targetCoordinates

                uiView.animateToCenter(targetCoordinates, 7)
            }
        }
    }

    private func updateCircleOverlay(
        _ mapView: MKMapView,
        _ coordinator: MoveOnMapCoordinator,
        _ radius: Double,
        _ center: CLLocationCoordinate2D,
    ) {
        let circleOverlay = map.overlays.first(where: { $0 is AnimatedCircleOverlay })
        if let circle = circleOverlay,
            circle.coordinate.approximatelyEquals(center) {
            coordinator.animationManager.animateRadius(to: radius)
        } else {
            if let overlay = circleOverlay {
                mapView.removeOverlay(overlay)
            }

            let updatedOverlay = AnimatedCircleOverlay(center: center, radius: radius)
            mapView.addOverlay(updatedOverlay)
        }
    }
}
