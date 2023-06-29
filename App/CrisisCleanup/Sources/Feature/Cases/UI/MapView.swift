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
    @Binding var totAnnots: Int
    @Binding var inViewAnnots: Int
    private var control: MapView
    
    init(_ control: MapView, _ viewModel: CasesViewModel, totAnnots: Binding<Int>, inViewAnnots: Binding<Int>)
    {
        self.control = control
        self.viewModel = viewModel
        self._totAnnots = totAnnots
        self._inViewAnnots = inViewAnnots
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
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        totAnnots = mapView.annotations.count
        inViewAnnots = mapView.annotations(in: mapView.visibleMapRect).count
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation.title != "My Location")
        {
            let reuseIdentifier = "annotationView"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            if #available(iOS 11.0, *) {
                if view == nil {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                }
                view?.displayPriority = .required
            }
            view?.annotation = annotation
            view?.canShowCallout = true
            
            view?.image = UIImage(named: "ic_work_type_animal_services", in: .module, with: .none)
   
            
            return view
        }
        return mapView.view(for: annotation)
    }
    
}



struct MapView : UIViewRepresentable {
    
    @Binding var map: MKMapView
    @Binding var totAnnots: Int
    @Binding var inViewAnnots: Int
    @Binding var prevIncident: Int64?
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
        Coordinator(self, self.viewModel, totAnnots: self.$totAnnots, inViewAnnots: self.$inViewAnnots)
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
        if(prevIncident == nil && viewModel.incidentsData.selectedId != -1 && uiView.annotations.count != viewModel.worksiteMapMarkers.count) {
            prevIncident = viewModel.incidentsData.selectedId
            updateAnnotations(from: uiView)
        } else if (prevIncident != viewModel.incidentsData.selectedId && uiView.annotations.count != viewModel.worksiteMapMarkers.count) {
            prevIncident = viewModel.incidentsData.selectedId
            updateAnnotations(from: uiView)
        }
        
        print("incident is \(viewModel.incidentsData.selectedId)")
        print("incident is \(viewModel.incidentsData.isLoading)")
        print("incident is \(viewModel.worksiteMapMarkers.count)")
      
  
    }
    
    private func updateAnnotations(from mapView: MKMapView) {
        
        mapView.removeAnnotations(mapView.annotations)
        
        var annotations: [MKAnnotation] = []
        for marker in viewModel.worksiteMapMarkers {
            let lat = marker.latLng.latitude
            let long = marker.latLng.longitude
            var pin = MKPointAnnotation()
            
            pin.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            annotations.append(pin)
            
        }

        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: false)

    }
    
    
}



