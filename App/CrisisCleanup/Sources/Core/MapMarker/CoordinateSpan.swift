import MapKit

extension MKCoordinateSpan {
    var isValid: Bool {
        longitudeDelta > 0 &&
        longitudeDelta < 360 &&
        latitudeDelta > 0 &&
        latitudeDelta < 180
    }
}
