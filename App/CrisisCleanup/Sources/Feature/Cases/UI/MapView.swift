//
//  SwiftUIView.swift
//  
//
//  Created by Anthony Aguilar on 6/26/23.
//


import Foundation
import SwiftUI
import MapKit

class Coordinator: NSObject, MKMapViewDelegate {
    
    @ObservedObject var viewModel: CasesViewModel
    private var control: MapView
    
    init(_ control: MapView, _ viewModel: CasesViewModel)
    {
        self.control = control
        self.viewModel = viewModel
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        if let annotationView = views.first {
        
            if let annotation = annotationView.annotation {
                if annotation is MKUserLocation {
                    let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
                    mapView.setRegion(region, animated: false)
                    
                }
                
            }
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
  
      }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation.title != "My Location")
        {
            let reuseIdentifier = "annotationView"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            if #available(iOS 11.0, *) {
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                }
                view?.displayPriority = .required
            }
            view?.annotation = annotation
            view?.canShowCallout = true
            return view
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
        map.delegate = context.coordinator
        
        return map
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, self.viewModel)
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
    
        updateAnnotations(from: uiView)
  
    }
    
    private func updateAnnotations(from mapView: MKMapView) {
        
        print("adding pins")
        mapView.removeAnnotations(mapView.annotations)
        var annotations: [MKAnnotation] = []
        for marker in viewModel.worksiteMapMarkers {
            let lat = marker.latLng.latitude
            let long = marker.latLng.longitude
            var pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            print(pin)
            annotations.append(pin)
            
        }

        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: false)

    }
    
    
}



