import MapKit

extension MKMapView {
    func setSatelliteMapType(_ isSatelliteView: Bool) {
        mapType = isSatelliteView ? .satellite : .standard
    }
}
