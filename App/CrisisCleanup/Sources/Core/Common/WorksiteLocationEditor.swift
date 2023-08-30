import CoreLocation

public protocol WorksiteLocationEditor {
    func takeEditedLocation() -> CLLocationCoordinate2D?
}
