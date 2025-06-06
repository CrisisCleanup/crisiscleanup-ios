import Combine
import CoreLocation

protocol MapCenterMover: MapViewRegionChangeListener {
    var mapCoordinatesPublisher: Published<CLLocationCoordinate2D>.Publisher { get }
    var isPinCenterScreenPublisher: Published<Bool>.Publisher { get }

    func subscribeLocationStatus() -> AnyCancellable

    func useMyLocation() -> Bool
    func updateCoordinates(_ coordinates: CLLocationCoordinate2D)
}

class AppMapCenterMover: MapCenterMover {
    private let locationManager: LocationManager

    private var isUserActed = false

    @Published private(set) var mapCoordinates = DefaultCoordinates2d
    var mapCoordinatesPublisher: Published<CLLocationCoordinate2D>.Publisher {
        $mapCoordinates
    }

    @Published private(set) var isPinCenterScreen = false
    var isPinCenterScreenPublisher: Published<Bool>.Publisher {
        $isPinCenterScreen
    }

    private var useMyLocationExpirationTime = Date.epochZero

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }

    func subscribeLocationStatus() -> AnyCancellable {
        locationManager.$locationPermission
            .receive(on: RunLoop.main)
            .sink {
                if let status = $0,
                   self.locationManager.isAuthorized(status),
                   self.useMyLocationExpirationTime.distance(to: Date.now) < 0.seconds {
                    self.setLocationCoordinates()
                }
            }
    }

    private func setLocationCoordinates() {
        if let location = locationManager.getLocation() {
            isPinCenterScreen = false

            mapCoordinates = location.coordinate
        }
    }

    func useMyLocation() -> Bool {
        if locationManager.requestLocationAccess() {
            setLocationCoordinates()
        } else {
            useMyLocationExpirationTime = Date.now.addingTimeInterval(20.seconds)
        }

        return !locationManager.isDeniedLocationAccess
    }

    func onRegionChange(
        _ mapCenter: CLLocationCoordinate2D,
        isUserAction: Bool,
        isMapMoving: Bool,
    ) {
        if isUserAction {
            isUserActed = true
        }

        isPinCenterScreen = isUserAction || (isUserActed && !isMapMoving)

        if isPinCenterScreen {
            mapCoordinates = mapCenter
        }
    }

    func updateCoordinates(_ coordinates: CLLocationCoordinate2D) {
        mapCoordinates = coordinates
    }
}
