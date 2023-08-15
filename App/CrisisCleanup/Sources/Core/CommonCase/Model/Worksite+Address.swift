import MapKit

extension Worksite {
    var fullAddress: String {
        [
            address,
            city,
            state,
            postalCode
        ].combineTrimText()
    }

    var addressQuery: (String, MKMapItem) {
        let addressText = fullAddress
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = addressText

        return (addressText, mapItem)
    }
}
