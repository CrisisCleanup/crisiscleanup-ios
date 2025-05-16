import Combine
import CoreLocation

protocol MapCenterMover {
    var mapCoordinates: any Publisher<CLLocationCoordinate2D, Never> { get }
    var isPinCenterScreen: Bool { get }

    func subscribeLocationStatus() -> AnyCancellable

    func setInitialCoordinates(_ coordinates: CLLocationCoordinate2D)
    func useMyLocation() -> Bool
    func onMapMove(mapCenter: CLLocationCoordinate2D)
    func updateCoordinates(_ coordinates: CLLocationCoordinate2D)
}

class AppMapCenterMover: MapCenterMover {
    private let locationManager: LocationManager

    private let mapCoordinatesSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(DefaultCoordinates2d)
    let mapCoordinates: any Publisher<CLLocationCoordinate2D, Never>

    private var isCoordinatesMovedGuard = false
    private var initialCoordinates = DefaultCoordinates2d

    private(set) var isPinCenterScreen = false

    private var useMyLocationExpirationTime = Date(timeIntervalSince1970: 0)

    init(locationManager: LocationManager) {
        self.locationManager = locationManager

        mapCoordinates = mapCoordinatesSubject
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

    func setInitialCoordinates(_ coordinates: CLLocationCoordinate2D) {
        mapCoordinatesSubject.value = coordinates
        initialCoordinates = coordinates
    }

    private func setLocationCoordinates() {
        if let location = locationManager.getLocation() {
            isPinCenterScreen = false
            mapCoordinatesSubject.value = location.coordinate
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

    private func isValidMapChange(_ coordinates: CLLocationCoordinate2D) -> Bool {
        if isCoordinatesMovedGuard {
            return true
        }

        if initialCoordinates.approximatelyEquals(DefaultCoordinates2d) {
            return false
        }
        if coordinates.approximatelyEquals(initialCoordinates, tolerance: 1e-3) {
            isCoordinatesMovedGuard = true
            return true
        }

        return false
    }

    func onMapMove(mapCenter: CLLocationCoordinate2D) {
        guard isValidMapChange(mapCenter) else {
            return
        }

        isPinCenterScreen = true

        mapCoordinatesSubject.value = mapCenter
    }

    func updateCoordinates(_ coordinates: CLLocationCoordinate2D) {
        mapCoordinatesSubject.value = coordinates
    }
}
