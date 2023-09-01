import CoreLocation
import CrisisCleanup

extension CLPlacemark {
    func asLocationAddress(_ coordinates: CLLocationCoordinate2D) -> LocationAddress {
        LocationAddress(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            address: [
                subThoroughfare ?? "",
                thoroughfare ?? "",
            ]
                .combineTrimText(" "),
            city: locality ?? "",
            county: subAdministrativeArea ?? "",
            state: administrativeArea ?? "",
            country: country ?? "",
            zipCode: postalCode ?? ""
        )
    }

    func asKeyLocationAddress(_ key: String, _ coordinates: CLLocationCoordinate2D) -> KeyLocationAddress {
        KeyLocationAddress(
            key: key,
            address: asLocationAddress(coordinates)
        )
    }
}
