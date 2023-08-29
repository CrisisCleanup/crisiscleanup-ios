//  Created by Anthony Aguilar on 7/11/23.

import Foundation
import MapKit
import SwiftUI

class CreateEditCaseMapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        overlayMapRenderer(overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.staticMapAnnotationView(annotation)
    }
}

struct CreateEditCaseMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var latLng: LatLng

    let isCreateWorksite: Bool
    let hasInitialCoordinates: Bool

    func makeUIView(context: Context) -> MKMapView {
        map.configure()

        map.delegate = context.coordinator

        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let coordinates = CLLocationCoordinate2D(latitude: latLng.latitude, longitude: latLng.longitude)
        let casePin = CustomPinAnnotation(coordinates, image)
        map.addAnnotation(casePin)
        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> CreateEditCaseMapCoordinator {
        CreateEditCaseMapCoordinator()
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CreateEditCaseMapView>) {
        if let annotation = uiView.annotations.firstOrNil,
           let pinAnnotation = annotation as? CustomPinAnnotation {
            let coordinates = CLLocationCoordinate2D(latitude: latLng.latitude, longitude: latLng.longitude)
            pinAnnotation.coordinate = coordinates

            var zoom = 12
            if isCreateWorksite && hasInitialCoordinates {
                zoom = 6
            }

            uiView.animaiteToCenter(coordinates, zoom)
        }
    }
}
