import CoreLocation
import MapKit
import SwiftUI

internal func makeCrisisCleanupPinAnnotation(
    _ coordinates: CLLocationCoordinate2D,
    imageName: String,
    id: String,
) -> CustomPinAnnotation {
    let image = UIImage(named: imageName, in: .module, with: .none)!
    return CustomPinAnnotation(
        coordinates,
        image: image,
        id: id,
    )
}

struct MoveMapView : UIViewRepresentable {
    @Binding var map: MKMapView

    var targetCoordinates: CLLocationCoordinate2D
    var isPinCenterScreen: Bool
    var isTargetOutOfBounds: Bool

    var regionChangeListener: MapViewRegionChangeListener

    private func makeAnnotation(imageName: String, id: String) -> CustomPinAnnotation {
        makeCrisisCleanupPinAnnotation(targetCoordinates, imageName: imageName, id: id)
    }

    func makeUIView(context: Context) -> MKMapView {
        let isNewMap = map.annotations.isEmpty

        map.configure(
            isScrollEnabled: true,
            isExistingMap: !isNewMap,
        )

        map.delegate = context.coordinator

        if isNewMap {
            let annotation = makeAnnotation(imageName: "cc_map_pin", id: "in-bounds")
            map.addAnnotation(annotation)
        }

        return map
    }

    func makeCoordinator() -> MoveMapCoordinator {
        MoveMapCoordinator(regionChangeListener: regionChangeListener)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MoveMapView>) {
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
}
