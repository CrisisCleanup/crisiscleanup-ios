import CoreLocation
import MapKit
import SwiftUI

struct CircleBoundMoveMapView : UIViewRepresentable {
    @Binding var map: MKMapView

    var regionChangeListener: MapViewRegionChangeListener
    var isScrollEnabled: Bool
    var targetCoordinates: CLLocationCoordinate2D
    var isPinCenterScreen: Bool
    var boundingRadius: Double

    func makeUIView(context: Context) -> MKMapView {
        let isNewMap = map.annotations.isEmpty

        map.configure(
            isScrollEnabled: isScrollEnabled,
            isExistingMap: !isNewMap,
        )

        map.delegate = context.coordinator

        if isNewMap {
            let annotation = makeCrisisCleanupPinAnnotation(
                targetCoordinates,
                imageName: "cc_map_pin",
                id: ""
            )
            map.addAnnotation(annotation)
        }

        return map
    }

    func makeCoordinator() -> MoveMapCoordinator {
        MoveMapCoordinator(regionChangeListener: regionChangeListener)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CircleBoundMoveMapView>) {
        uiView.isScrollEnabled = isScrollEnabled

        if boundingRadius > 0 {
            updateCircleOverlay(
                uiView,
                context.coordinator,
                boundingRadius.milesToMeters,
                targetCoordinates,
            )
        }

        if let annotation = uiView.annotations.first(where: { $0 is CustomPinAnnotation }),
           let customAnnotation = annotation as? CustomPinAnnotation {
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
        _ coordinator: MoveMapCoordinator,
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
