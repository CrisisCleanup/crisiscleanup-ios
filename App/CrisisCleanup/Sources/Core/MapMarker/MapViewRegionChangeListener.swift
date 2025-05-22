import CoreLocation

protocol MapViewRegionChangeListener {
    func onRegionChange(
        _ mapCenter: CLLocationCoordinate2D,
        isUserAction: Bool,
        isMapMoving: Bool
    )
}
