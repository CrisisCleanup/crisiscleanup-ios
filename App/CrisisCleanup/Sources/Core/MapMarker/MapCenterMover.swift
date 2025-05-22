import Combine
import CoreLocation

// TODO: Improve state management
//       Refactor into separate use Cases
protocol MapCenterMover {
    var mapCoordinatesPublisher: Published<CLLocationCoordinate2D>.Publisher { get }
    var isPinCenterScreenPublisher: Published<Bool>.Publisher { get }

    // TODO: Research better design
    var isMapLoadedPublisher: any Publisher<Bool, Never> { get }

    var isUserActed: Bool { get }

    func subscribeLocationStatus() -> AnyCancellable
    // TODO: Research better design
    func subscribeMapLoad() -> AnyCancellable

    func setInitialCoordinates(_ coordinates: CLLocationCoordinate2D)

    func useMyLocation() -> Bool
    func onMapMove(
        _ mapCenter: CLLocationCoordinate2D,
        isUserAction: Bool,
        isMapMoving: Bool
    )
    func updateCoordinates(_ coordinates: CLLocationCoordinate2D)
    func overridePinCenterScreen(_ pin: Bool?)
}

class AppMapCenterMover: MapCenterMover {
    private let locationManager: LocationManager

    private(set) var isUserActed = false

    @Published private(set) var mapCoordinates = DefaultCoordinates2d
    var mapCoordinatesPublisher: Published<CLLocationCoordinate2D>.Publisher {
        $mapCoordinates
    }

    private var isCoordinatesMovedGuard = false
    private var initialCoordinates = DefaultCoordinates2d

    @Published private(set) var isPinCenterScreen = false
    var isPinCenterScreenPublisher: Published<Bool>.Publisher {
        $isPinCenterScreen
    }

    private var useMyLocationExpirationTime = Date(timeIntervalSince1970: 0)

    private var overridePinCenter: Bool? = nil

    // TODO: Research better design
    //       Hack due to too many animations interrupting one another
    //       Figure how to set view state after map (and views) have settled all animations
    private let mapLoadSubject = CurrentValueSubject<Date, Never>(Date.now)
    let isMapLoadedSubject = CurrentValueSubject<Bool, Never>(false)
    var isMapLoadedPublisher: any Publisher<Bool, Never>

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        isMapLoadedPublisher = isMapLoadedSubject
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

    func subscribeMapLoad() -> AnyCancellable {
        mapLoadSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.current)
            .sink { _ in
                if !self.isMapLoadedSubject.value {
                    self.isMapLoadedSubject.value = true
                }
            }
    }

    func setInitialCoordinates(_ coordinates: CLLocationCoordinate2D) {
        mapCoordinates = coordinates
        initialCoordinates = coordinates
    }

    private func setLocationCoordinates() {
        if let location = locationManager.getLocation() {
            if overridePinCenter == nil {
                isPinCenterScreen = false
            }

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

    private func isValidMapChange(
        _ coordinates: CLLocationCoordinate2D,
        isUserAction: Bool
    ) -> Bool {
        if isCoordinatesMovedGuard {
            return true
        }

        if isUserAction {
            isCoordinatesMovedGuard = true
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

    func onMapMove(
        _ mapCenter: CLLocationCoordinate2D,
        isUserAction: Bool,
        isMapMoving: Bool,
    ) {
        mapLoadSubject.value = Date.now

        guard isValidMapChange(mapCenter, isUserAction: isUserAction) else {
            return
        }

        if isUserAction {
            isUserActed = true
        }

        if isUserAction || !isMapMoving {
            if overridePinCenter == nil  {
                isPinCenterScreen = true
            }

            if overridePinCenter == true || isPinCenterScreen {
                mapCoordinates = mapCenter
            }
        }
    }

    func updateCoordinates(_ coordinates: CLLocationCoordinate2D) {
        mapCoordinates = coordinates
    }

    func overridePinCenterScreen(_ pin: Bool?) {
        overridePinCenter = pin
    }
}
