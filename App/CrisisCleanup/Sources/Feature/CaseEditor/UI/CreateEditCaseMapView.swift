//  Created by Anthony Aguilar on 7/11/23.

import Foundation
import MapKit
import SwiftUI

class CreateEditCaseMapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        staticMapRenderer(for: overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.staticMapAnnotationView(annotation)
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//        imgView.center = mapView.center
//        imgView.center.y = imgView.center.y - (imgView.image?.size.height ?? 0)/2
//
//        mapView.addSubview(imgView)
    }
}

struct CreateEditCaseMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var caseCoordinates: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        map.configureStaticMap()

        map.delegate = context.coordinator

        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let casePin = CustomPinAnnotation(caseCoordinates, image)
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
            pinAnnotation.coordinate = caseCoordinates
            uiView.setCenter(caseCoordinates, animated: true)

            uiView.animaiteToCenter(caseCoordinates)
        }
    }
}
