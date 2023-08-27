//  Created by Anthony Aguilar on 7/5/23.

import CoreGraphics
import Foundation
import MapKit
import SwiftUI

class ViewCaseMapCoordinator: NSObject, MKMapViewDelegate {

    var caseCoordinates: CLLocationCoordinate2D

    init(
        _ caseCoordinates: CLLocationCoordinate2D
    ) {
        self.caseCoordinates = caseCoordinates
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return createPolygonRenderer(for: overlay as! MKPolygon)
    }

    let reuseIdentifier = "reuse-identifier"
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) else {
            if let annotation = annotation as? CustomPinAnnotation {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                view.image = annotation.image
                return view
            }
            return nil
        }
        return annotationView
    }

    func createPolygonRenderer(for polygon: MKPolygon) -> MKPolygonRenderer {
        let renderer = MKPolygonRenderer(polygon: polygon)
        renderer.alpha = 0.5
        renderer.lineWidth = 0
        renderer.fillColor = UIColor.black
        renderer.blendMode = .color
        return renderer
    }
}

struct ViewCaseMapView : UIViewRepresentable {

    @Binding var map: MKMapView
    var caseCoordinates: CLLocationCoordinate2D

    let firstHalf = [
        CLLocationCoordinate2D(latitude: -90, longitude: -180),
        CLLocationCoordinate2D(latitude: -90, longitude: 0),
        CLLocationCoordinate2D(latitude: 90, longitude: 0),
        CLLocationCoordinate2D(latitude: 90, longitude: -180)
    ]

    let secondHalf = [
        CLLocationCoordinate2D(latitude: 90, longitude: 0),
        CLLocationCoordinate2D(latitude: 90, longitude: 180),
        CLLocationCoordinate2D(latitude: -90, longitude: 180),
        CLLocationCoordinate2D(latitude: -90, longitude: 0)
    ]

    var firstHalfOverlay: MKPolygon {
        return MKPolygon(coordinates: firstHalf, count: firstHalf.count)
    }

    var secondHalfOverlay: MKPolygon {
        return MKPolygon(coordinates: secondHalf, count: secondHalf.count)
    }

    func makeUIView(context: Context) -> MKMapView {
        map.overrideUserInterfaceStyle = .light
        map.mapType = .standard
        map.pointOfInterestFilter = .excludingAll
        map.camera.centerCoordinateDistance = 20
        map.showsUserLocation = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.isZoomEnabled = true
        map.isScrollEnabled = false

        map.addOverlay(firstHalfOverlay, level: .aboveRoads)
        map.addOverlay(secondHalfOverlay, level: .aboveRoads)

        map.delegate = context.coordinator

        // TODO: This image likely needs offsetting. Investigate and offset or delete comment.
        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let casePin = CustomPinAnnotation(caseCoordinates, image)
        map.addAnnotation(casePin)
        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> ViewCaseMapCoordinator {
        ViewCaseMapCoordinator(caseCoordinates)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<ViewCaseMapView>) {
    }
}

class CustomPinAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var image: UIImage?

    init(
        _ coordinate: CLLocationCoordinate2D,
        _ image: UIImage? = nil
    ) {
        self.coordinate = coordinate
        self.image = image
        super.init()
    }
}
