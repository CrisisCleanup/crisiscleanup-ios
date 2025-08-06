//  Created by Anthony Aguilar on 6/26/23.

import Foundation
import SwiftUI
import MapKit

extension MKMapView {
    var zoomLevel: Double {
        let center = region.center
        let span = region.span
        let centerFlatSpacePoint = MKMapPoint(center)
        let topLeftFlatSpacePoint = MKMapPoint(CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta * 0.5,
            longitude: center.longitude - span.longitudeDelta * 0.5,
        ))
        let zoomWidth = (centerFlatSpacePoint.x - topLeftFlatSpacePoint.x) * 2
        let viewBoundsWidth = bounds.size.width
        let zoomScale = zoomWidth / Double(viewBoundsWidth)
        let zoomExponent = log2(zoomScale)
        let z = 21 - zoomExponent

        return z
    }

    func region(
        for zoom: Double,
        spanDelta: Double = 0,
    ) -> MKCoordinateRegion {
        let zoomExponent = 21 - zoom
        let zoomScale = pow(2.0, zoomExponent)

        let viewBoundsWidth = bounds.size.width
        let zoomWidth = zoomScale * Double(viewBoundsWidth)

        let viewBoundsHeight = bounds.size.height
        let zoomHeight = zoomScale * Double(viewBoundsHeight)

        let center = region.center
        let centerFlatSpacePoint = MKMapPoint(center)
        let leftFlatSpacePoint = centerFlatSpacePoint.x - zoomWidth / 2
        let topFlatSpacePoint = centerFlatSpacePoint.y - zoomHeight / 2
        let topLeftFlatSpacePoint = MKMapPoint(x: leftFlatSpacePoint, y: topFlatSpacePoint)
        let topLeftCoordinate = topLeftFlatSpacePoint.coordinate

        let span = MKCoordinateSpan(
            latitudeDelta: (topLeftCoordinate.latitude - center.latitude) * 2 + spanDelta,
            longitudeDelta: (center.longitude - topLeftCoordinate.longitude) * 2 + spanDelta,
        )
        let region = MKCoordinateRegion(center: center, span: span)

        return region
    }
}

class CasesMapViewCoordinator: NSObject, MKMapViewDelegate {
    let viewModel: CasesViewModel
    let onSelectWorksite: (Int64) -> Void

    fileprivate var isTintApplied: Bool = false

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
        let zoom = mapView.zoomLevel

        // There is a bug with map view where sometimes the map is animating but regionDidChangeAnimated doesn't report it correctly.
        // Assume animation should always happen so inform view model when not reported
        viewModel.onMapCameraChange(zoom, mapView.region, animated)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let overlay as MKPolygon:
            return isTintApplied ? overlayMapRenderer(overlay, 1.0) : BlankRenderer(overlay: overlay)
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
                view.centerOffset = annotationMapMark.mapIconOffset
                return view
            }
            return annotationView
        }
        return mapView.view(for: annotation)
    }

    private func createTileRenderer(for overlay: MKTileOverlay) -> MKTileOverlayRenderer {
        MKTileOverlayRenderer(tileOverlay: overlay)
    }
}

internal struct CasesMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var focusWorksiteCenter: CLLocationCoordinate2D?
    @Binding var isSatelliteMapType: Bool

    @ObservedObject var viewModel: CasesViewModel

    let mapOverlays: [MKOverlay]

    let onSelectWorksite: (Int64) -> Void

    func makeUIView(context: Context) -> MKMapView {
        map.configure(
            overlays: mapOverlays,
            isScrollEnabled: true
        )

        if let overlay = viewModel.debugOverlay{
            map.addOverlay(overlay, level: .aboveLabels)
        }
        map.addOverlay(viewModel.mapDotsOverlay, level: .aboveLabels)

        map.delegate = context.coordinator

        viewModel.mapView = map

        return map
    }

    func makeCoordinator() -> CasesMapViewCoordinator {
        CasesMapViewCoordinator(viewModel, onSelectWorksite)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CasesMapView>) {
        if let worksiteCoordinates = focusWorksiteCenter {
            uiView.animateToCenter(worksiteCoordinates, zoomLevel: 14)
            Task { @MainActor in
                viewModel.editedWorksiteLocation = nil
            }
        }

        if let coordinator = (map.delegate as? Coordinator),
           coordinator.isTintApplied == isSatelliteMapType {
            // Overlays references don't match on first toggle
            let polygonOverlays = map.overlays.filter { $0 is MKPolygon }
            map.removeOverlays(polygonOverlays)

            coordinator.isTintApplied = !isSatelliteMapType
            if !isSatelliteMapType {
                map.addOverlays(mapOverlays)
            }
        }
    }
}
