import CoreLocation

protocol WorksiteLocationEditor {
    func takeEditedLocation() -> CLLocationCoordinate2D?
}
