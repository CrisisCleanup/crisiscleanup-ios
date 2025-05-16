//  Created by Anthony Aguilar on 7/5/23.

import Foundation
import MapKit
import SwiftUI

class ViewCaseMapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        overlayMapRenderer(overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.staticMapAnnotationView(annotation)
    }
}

struct ViewCaseMapView : UIViewRepresentable {
    @Binding var map: MKMapView

    var caseCoordinates: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        map.configure()

        map.delegate = context.coordinator

        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let casePin = CustomPinAnnotation(caseCoordinates, image: image)
        map.addAnnotation(casePin)
        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> ViewCaseMapCoordinator {
        ViewCaseMapCoordinator()
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<ViewCaseMapView>) {
        uiView.animaiteToCenter(caseCoordinates)
    }
}
