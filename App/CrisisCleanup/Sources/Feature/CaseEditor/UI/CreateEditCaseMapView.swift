//  Created by Anthony Aguilar on 7/11/23.

import Foundation
import MapKit
import SwiftUI

struct CreateEditCaseMapView : UIViewRepresentable, MapViewContainer {
    @Binding var map: MKMapView
    @Binding var latLng: LatLng

    let isSatelliteMapType: Bool
    let mapOverlays: [MKOverlay]

    let isCreateWorksite: Bool
    let hasInitialCoordinates: Bool

    func makeUIView(context: Context) -> MKMapView {
        map.configure(
            overlays: mapOverlays,
            isSatelliteView: isSatelliteMapType,
        )

        map.delegate = context.coordinator

        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let casePin = CustomPinAnnotation(latLng.coordinates, image: image)
        map.addAnnotation(casePin)
        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> StaticMapCoordinator {
        StaticMapCoordinator(isTintApplied: !isSatelliteMapType)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<CreateEditCaseMapView>) {
        if let annotation = uiView.annotations.firstOrNil,
           let pinAnnotation = annotation as? CustomPinAnnotation {
            let coordinates = latLng.coordinates
            pinAnnotation.coordinate = coordinates

            let zoom = isCreateWorksite && hasInitialCoordinates ? 6 : 12

            uiView.animateToCenter(coordinates, zoomLevel: zoom)
        }

        syncMapOverlays(map, mapOverlays)
    }
}
