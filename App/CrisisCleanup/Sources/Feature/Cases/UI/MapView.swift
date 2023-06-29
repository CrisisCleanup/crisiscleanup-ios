//  Created by Anthony Aguilar on 6/26/23.

import Foundation
import SwiftUI
import MapKit

class Coordinator: NSObject, MKMapViewDelegate {
    var viewModel: CasesViewModel

    init(_ viewModel: CasesViewModel)
    {
        self.viewModel = viewModel
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // From https://medium.com/@dmytrobabych/getting-actual-rotation-and-zoom-level-for-mapkit-mkmapview-e7f03f430aa9
        let zoom = log2(360.0 * mapView.frame.size.width / (mapView.region.span.longitudeDelta * 128))
        viewModel.onMapCameraChange(zoom, mapView.region)
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

                view.image = annotationMapMark.mapIcon ?? UIImage(named: "ic_work_type_animal_services", in: .module, with: .none)
                return view
            }
            return annotationView
        }
        return mapView.view(for: annotation)
    }

}

struct MapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @ObservedObject var viewModel: CasesViewModel

    func makeUIView(context: Context) -> MKMapView {
        map.overrideUserInterfaceStyle = .dark
        map.mapType = MKMapType.mutedStandard
        map.pointOfInterestFilter = .excludingAll
        map.camera.centerCoordinateDistance = 20
        map.showsUserLocation = false
        map.isRotateEnabled = false
        //        map.insertOverlay(MKO, at: 1)
        map.delegate = context.coordinator

        return map
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
    }
}
