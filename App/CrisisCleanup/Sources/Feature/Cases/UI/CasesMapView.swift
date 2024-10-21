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
        if let firstAnnotation = mapView.selectedAnnotations.firstOrNil,
           let selected = firstAnnotation as? WorksiteAnnotationMapMark {
            onSelectWorksite(selected.source.id)
        }
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
        switch overlay {
        case let overlay as MKPolygon:
            return createPolygonRenderer(for: overlay)
        case let overlay as MKTileOverlay:
            return createTileRenderer(for: overlay)
        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotationMapMark = annotation as? WorksiteAnnotationMapMark {
            let reuseIdentifier = annotationMapMark.reuseIdentifier!
            guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) else {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                view.displayPriority = .required
                view.annotation = annotation

                view.image = annotationMapMark.mapIcon ?? UIImage(named: "ic_work_type_unknown", in: .module, with: .none)
                return view
            }
            return annotationView
        }
        return mapView.view(for: annotation)
    }

    func createPolygonRenderer(for polygon: MKPolygon) -> MKPolygonRenderer {
        overlayMapRenderer(polygon, 1.0)
    }

    func createTileRenderer(for overlay: MKTileOverlay) -> MKTileOverlayRenderer {
        MKTileOverlayRenderer(tileOverlay: overlay)
    }
}

internal struct CasesMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var focusWorksiteCenter: CLLocationCoordinate2D?

    @ObservedObject var viewModel: CasesViewModel

    let onSelectWorksite: (Int64) -> Void

    func makeUIView(context: Context) -> MKMapView {
        map.overrideUserInterfaceStyle = .light
        map.mapType = .standard
        map.pointOfInterestFilter = .excludingAll
        map.camera.centerCoordinateDistance = 20
        map.showsUserLocation = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false

        map.overlayPolygons()

        if let overlay = viewModel.debugOverlay{
            map.addOverlay(overlay, level: .aboveLabels)
        }
        map.addOverlay(viewModel.mapDotsOverlay, level: .aboveLabels)

        map.delegate = context.coordinator

        viewModel.mapView = map

        return map
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel, onSelectWorksite)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CasesMapView>) {
        if let worksiteCoordinates = focusWorksiteCenter {
            uiView.animaiteToCenter(worksiteCoordinates)
            Task { @MainActor in
                viewModel.editedWorksiteLocation = nil
            }
        }
    }
}
