import Combine
import CoreLocation
import Foundation

protocol CircleBoundMapMover: MapViewRegionChangeListener {
    var isUserActedPublisher: Published<Bool>.Publisher { get }

    var mapCoordinatesPublisher: Published<CLLocationCoordinate2D>.Publisher { get }

    func subscribeLocationStatus() -> AnyCancellable

    func useMyLocation() -> Bool
    func updateCoordinates(_ coordinates: CLLocationCoordinate2D)
}

class AppCircleBoundMapMover: CircleBoundMapMover {
    private let locationManager: LocationManager

    @Published private(set) var isUserActed = false
    var isUserActedPublisher: Published<Bool>.Publisher {
        $isUserActed
    }

    @Published private(set) var mapCoordinates = DefaultCoordinates2d
    var mapCoordinatesPublisher: Published<CLLocationCoordinate2D>.Publisher {
        $mapCoordinates
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

        if !isUserActed {
            return
        }

        if isUserAction || !isMapMoving {
            mapCoordinates = mapCenter
        }
    }

    func updateCoordinates(_ coordinates: CLLocationCoordinate2D) {
        mapCoordinates = coordinates
    }
}
