//  Created by Anthony Aguilar on 7/5/23.

import Foundation
import MapKit
import SwiftUI

struct ViewCaseMapView : UIViewRepresentable, MapViewContainer {
    @Binding var map: MKMapView
    let isSatelliteMapType: Bool
    let mapOverlays: [MKOverlay]

    let caseCoordinates: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        map.configure(
            overlays: mapOverlays,
            isSatelliteView: isSatelliteMapType,
        )

        map.delegate = context.coordinator

        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let casePin = CustomPinAnnotation(caseCoordinates, image: image)
        map.addAnnotation(casePin)
        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> StaticMapCoordinator {
        StaticMapCoordinator(isTintApplied: !isSatelliteMapType)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<ViewCaseMapView>) {
        uiView.animateToCenter(caseCoordinates)

        syncMapOverlays(map, mapOverlays)
    }
}
