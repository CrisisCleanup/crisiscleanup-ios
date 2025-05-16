import CoreLocation

protocol MoveMapChangeListener {
    var isPinCenterScreen: Bool { get }

    func onMapChange(mapCenter: CLLocationCoordinate2D)
}
