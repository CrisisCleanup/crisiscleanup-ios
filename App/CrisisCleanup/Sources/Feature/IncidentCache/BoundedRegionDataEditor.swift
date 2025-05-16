import Combine
import CoreLocation
import MapKit

protocol BoundedRegionDataEditor {
    var mapView: MKMapView? { get set }
    var centerCoordinates: any Publisher<CLLocationCoordinate2D, Never> { get }

    var showExplainPermissionLocation: any Publisher<Bool, Never> { get }

    var isUserActed: Bool { get }

    func onMapCameraChange(
        _ zoom: Double,
        _ region: MKCoordinateRegion,
        _ didAnimate: Bool
    )

    func centerOnLocation()
    func setCoordinates(latitude: Double, longitude: Double)

    func checkMyLocation() -> CLAuthorizationStatus
    func useMyLocation()
}

class IncidentCacheBoundedRegionDataEditor: BoundedRegionDataEditor {
    private let locationManager: LocationManager

    var mapView: MKMapView? = nil

    private let centerCoordinatesSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(CLLocationCoordinate2D(latitude: 0, longitude: 0))
    let centerCoordinates: any Publisher<CLLocationCoordinate2D, Never>

    private let showExplainPermissionLocationSubject = CurrentValueSubject<Bool, Never>(false)
    let showExplainPermissionLocation: any Publisher<Bool, Never>

    private(set) var isUserActed = false

    init(
        locationManager: LocationManager
    ) {
        self.locationManager = locationManager
        centerCoordinates = centerCoordinatesSubject
        showExplainPermissionLocation = showExplainPermissionLocationSubject
    }

    func onMapCameraChange(
        _ zoom: Double,
        _ region: MKCoordinateRegion,
        _ didAnimate: Bool
    ) {
        // TODO: Do
    }

    func centerOnLocation() {
        // TODO: Do
    }

    func setCoordinates(latitude: Double, longitude: Double) {
        // TODO: Do
    }

    func checkMyLocation() -> CLAuthorizationStatus {
        // TODO: Do
        return .notDetermined
    }

    func useMyLocation() {
        // TODO: Do
    }
}
