import MapKit

extension MKMapView {
    func animaiteToCenter(
        _ center: CLLocationCoordinate2D,
        _ zoomLevel: Int = 9
    ) {
        let zoom = zoomLevel < 0 || zoomLevel > 20 ? 9 : zoomLevel

        let zoomScale = 1.0 / pow(2.0, Double(zoom))
        let latDelta = 180.0 * zoomScale
        let longDelta = 360.0 * zoomScale
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)

        let regionCenter = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude), span: span)
        let region = regionThatFits(regionCenter)
        setRegion(region, animated: true)
    }
}
