//  Created by Anthony Aguilar on 7/11/23.

import CoreGraphics
import Foundation
import MapKit
import SwiftUI

class CreateEditCaseMapCoordinator: NSObject, MKMapViewDelegate {

    @Binding var caseCoordinates: CLLocationCoordinate2D

    init(
        _ caseCoordinates: Binding<CLLocationCoordinate2D>
    ) {
        self._caseCoordinates = caseCoordinates
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return createPolygonRenderer(for: overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
//        print(center)
        self.caseCoordinates = center
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        switch newState {
           case .starting:
               view.dragState = .dragging
           case .ending, .canceling:
               view.dragState = .none
           default: break
           }
    }


    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
//        print(center)
        self.caseCoordinates = center
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
    @State var toggled: Bool

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
//        map.isScrollEnabled = false

        map.addOverlay(firstHalfOverlay, level: .aboveRoads)
        map.addOverlay(secondHalfOverlay, level: .aboveRoads)

        map.delegate = context.coordinator

        // TODO: This image likely needs offsetting. Investigate and offset or delete comment.
        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!.withRenderingMode(.alwaysOriginal)

        let casePin = CustomPinAnnotation(caseCoordinates, image)
        casePin.coordinate = map.centerCoordinate

//        map.addSubview()
//        var imgView = UIImageView(image: image)
//        imgView.center = map.center //CGPoint(x: map.bounds.size.width/2, y: map.bounds.size.height/2)
//
//        print(imgView.center)
//        print(map.center)
////        print(imgView.widthAnchor.description)
////        print(imgView.image.)
//        map.addSubview(imgView)
//        map.didAddSubview(imgView)
//        map.addSubview(MyView())

//        let overlay =overlay
//        MKPinAnnotationView(annotation: <#T##MKAnnotation?#>, reuseIdentifier: <#T##String?#>)
//        map.addAnnotation(casePin)
//        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> CreateEditCaseMapCoordinator {
        CreateEditCaseMapCoordinator($caseCoordinates)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CreateEditCaseMapView>) {

        if(toggled && map.center != CGPoint(x: 0, y: 0))
        {
            let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!.withRenderingMode(.alwaysOriginal)
            var imgView = UIImageView(image: image)
            imgView.center = map.center //CGPoint(x: map.bounds.size.width/2, y: map.bounds.size.height/2)

            print(imgView.center)
            print(map.center)
            //        print(imgView.widthAnchor.description)
            //        print(imgView.image.)
            map.addSubview(imgView)
        }
    }
}

//class MyView: UIView {
//    // 1
//    private var label: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = UIFont.preferredFont(forTextStyle: .title1)
//        label.text = "Hello, UIKit!"
//        label.textAlignment = .center
//
//        return label
//    }()
//
//    private var imageView: UIImageView {
//        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!.withRenderingMode(.alwaysOriginal)
//        let imageView = UIImageView(image: image)
//        return imageView
//    }
//
//    init() {
//        super.init(frame: .zero)
//        // 2
//        backgroundColor = .systemPink
//
//        // 3
//        addSubview(imageView)
////        NSLayoutConstraint.activate([
////            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
////            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
////            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
////            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
////        ])
//
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
