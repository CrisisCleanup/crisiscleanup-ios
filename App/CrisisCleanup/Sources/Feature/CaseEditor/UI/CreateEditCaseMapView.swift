//  Created by Anthony Aguilar on 7/11/23.

import CoreGraphics
import Foundation
import MapKit
import SwiftUI

class CreateEditCaseMapCoordinator: NSObject, MKMapViewDelegate {

    @Binding var caseCoordinates: CLLocationCoordinate2D
    @Binding var imgView: UIImageView

    init(
        _ caseCoordinates: Binding<CLLocationCoordinate2D>,
        _ imgView: Binding<UIImageView>
    ) {
        self._caseCoordinates = caseCoordinates
        self._imgView = imgView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return createPolygonRenderer(for: overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "reuse-identifier"
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) else {
            if let annotation = annotation as? CustomPinAnnotation {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                view.image = annotation.image
                view.isDraggable = true
                view.animatesWhenAdded = true
                return view
            }
            return nil
        }
        return annotationView
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        imgView.center = mapView.center
        imgView.center.y = imgView.center.y - (imgView.image?.size.height ?? 0)/2

        mapView.addSubview(imgView)
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

struct CreateEditCaseMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @State var caseCoordinates: CLLocationCoordinate2D
    @State var imgView = UIImageView(image: UIImage(named: "cc_map_pin", in: .module, with: .none)!.withRenderingMode(.alwaysOriginal))

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
        map.showsUserLocation = true
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.isZoomEnabled = true

        map.addOverlay(firstHalfOverlay, level: .aboveRoads)
        map.addOverlay(secondHalfOverlay, level: .aboveRoads)

        map.delegate = context.coordinator

        return map
    }

    func makeCoordinator() -> CreateEditCaseMapCoordinator {
        CreateEditCaseMapCoordinator($caseCoordinates, $imgView)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CreateEditCaseMapView>) {
    }
}
