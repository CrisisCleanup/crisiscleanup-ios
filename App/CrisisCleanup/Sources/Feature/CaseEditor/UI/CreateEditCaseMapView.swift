//  Created by Anthony Aguilar on 7/11/23.

import CoreGraphics
import Foundation
import MapKit
import SwiftUI

class CreateEditCaseMapCoordinator: NSObject, MKMapViewDelegate {
    let caseCoordinates: CLLocationCoordinate2D
    private let pinImage: UIImage = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        .withRenderingMode(.alwaysOriginal)

    init(_ caseCoordinates: CLLocationCoordinate2D) {
        self.caseCoordinates = caseCoordinates
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        createPolygonRenderer(for: overlay as! MKPolygon)
    }

    private let reuseIdentifier = "reuse-identifier"
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

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if mapView.annotations.isEmpty {
            mapView.addAnnotation(CustomPinAnnotation(caseCoordinates, pinImage))
        }

//        imgView.center = mapView.center
//        imgView.center.y = imgView.center.y - (imgView.image?.size.height ?? 0)/2
//
//        mapView.addSubview(imgView)
    }

    private func createPolygonRenderer(for polygon: MKPolygon) -> MKPolygonRenderer {
        let renderer = MKPolygonRenderer(polygon: polygon)
        renderer.alpha = 0.5
        renderer.lineWidth = 0
        renderer.fillColor = UIColor.black
        renderer.blendMode = .color
        return renderer
    }
}

struct CreateEditCaseMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var caseCoordinates: CLLocationCoordinate2D

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
        map.isScrollEnabled = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false

        map.addOverlay(firstHalfOverlay, level: .aboveRoads)
        map.addOverlay(secondHalfOverlay, level: .aboveRoads)

        map.delegate = context.coordinator

        return map
    }

    func makeCoordinator() -> CreateEditCaseMapCoordinator {
        CreateEditCaseMapCoordinator(caseCoordinates)
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
