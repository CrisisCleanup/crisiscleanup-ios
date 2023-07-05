//  Created by Anthony Aguilar on 6/26/23.

import Foundation
import SwiftUI
import MapKit

class Coordinator: NSObject, MKMapViewDelegate {
    let viewModel: CasesViewModel
    let onSelectWorksite: (Int64) -> Void

    init(
        _ viewModel: CasesViewModel,
        _ onSelectWorksite: @escaping (Int64) -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectWorksite = onSelectWorksite
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selected = mapView.selectedAnnotations[0] as! WorksiteAnnotationMapMark
        onSelectWorksite(selected.source.id)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // From https://medium.com/@dmytrobabych/getting-actual-rotation-and-zoom-level-for-mapkit-mkmapview-e7f03f430aa9
        let zoom = log2(360.0 * mapView.frame.size.width / (mapView.region.span.longitudeDelta * 128))

        // There is a bug with map view where sometimes the map is animating but regionDidChangeAnimated doesn't report it correctly.
        // Assume animation should always happen so inform view model when not reported
        viewModel.onMapCameraChange(zoom, mapView.region, animated)
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

struct MapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @ObservedObject var viewModel: CasesViewModel
    let onSelectWorksite: (Int64) -> Void

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

        map.addOverlay(firstHalfOverlay, level: .aboveRoads)
        map.addOverlay(secondHalfOverlay, level: .aboveRoads)

        map.delegate = context.coordinator

        return map
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel, onSelectWorksite)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
    }
}
