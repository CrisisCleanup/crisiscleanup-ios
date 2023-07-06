//
//  ViewCaseMapView.swift
//
//  Created by Anthony Aguilar on 7/5/23.
//


import Foundation
import SwiftUI
import MapKit

class ViewCaseMapCoordinator: NSObject, MKMapViewDelegate {

    var caseCoordinates: CLLocationCoordinate2D

    init(
        _ caseCoordinates: CLLocationCoordinate2D
    ) {
        self.caseCoordinates = caseCoordinates
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    }


    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return createPolygonRenderer(for: overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is WorksiteAnnotationMapMark)
        {
            let annotationMapMark = annotation as! WorksiteAnnotationMapMark
            let reuseIdentifier = annotationMapMark.reuseIdentifier!
            guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) else {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                view.displayPriority = .required
                view.annotation = annotation
                view.canShowCallout = true

                view.image = annotationMapMark.mapIcon ?? UIImage(named: "ic_work_type_unknown", in: .module, with: .none)
                return view
            }
            return annotationView
        }
        return mapView.view(for: annotation)
    }

    func createPolygonRenderer(for polygon: MKPolygon) -> MKPolygonRenderer {
        let renderer = MKPolygonRenderer(polygon: polygon)
        renderer.alpha = 0.9
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
        map.isZoomEnabled = false
        map.isScrollEnabled = false

        map.addOverlay(firstHalfOverlay, level: .aboveRoads)
        map.addOverlay(secondHalfOverlay, level: .aboveRoads)

        map.delegate = context.coordinator

        let casePin = MKPointAnnotation()
        casePin.coordinate = caseCoordinates

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
