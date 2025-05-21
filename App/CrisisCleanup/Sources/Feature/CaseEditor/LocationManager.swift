//  Created by Anthony Aguilar on 7/12/23.

import Combine
import Foundation
import MapKit

public class LocationManager: NSObject, ObservableObject {
    private let logger: AppLogger
    private let locationManager = CLLocationManager()

    private let locationPermissionSubject = CurrentValueSubject<CLAuthorizationStatus?, Never>(nil)
    @Published private(set) var locationPermission: CLAuthorizationStatus? = nil

    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    @Published var location: CLLocation? = nil

    private let authorizedLocationAccessStatuses: Set<CLAuthorizationStatus> = [
        .authorizedAlways,
        .authorizedWhenInUse
    ]
    private let noLocationAccessStatuses: Set<CLAuthorizationStatus> = [
        .denied,
    ]
    var hasLocationAccess: Bool { isAuthorized(locationManager.authorizationStatus) }

    var isDeniedLocationAccess: Bool { noLocationAccessStatuses.contains(locationManager.authorizationStatus) }

    private var subscriptions = Set<AnyCancellable>()

    init(
        loggerFactory: AppLoggerFactory
    ) {
        logger = loggerFactory.getLogger("location")

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = CLLocationDistance(1000.0)

        locationPermissionSubject.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.locationPermission, on: self)
            .store(in: &subscriptions)
        locationPermissionSubject.value = locationManager.authorizationStatus

        locationSubject
            .receive(on: RunLoop.main)
            .assign(to: \.location, on: self)
            .store(in: &subscriptions)
    }

    func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        authorizedLocationAccessStatuses.contains(status)
    }

    func requestLocationAccess() -> Bool {
        if hasLocationAccess || isDeniedLocationAccess {
            locationPermissionSubject.value = locationManager.authorizationStatus
        } else {
            locationPermissionSubject.value = nil
            self.locationManager.requestWhenInUseAuthorization()
        }
        return hasLocationAccess
    }

    func getLocation() -> CLLocation? {
        let reportedLocation = locationManager.location
        // TODO: Might be wise to check timestamp before broadcasting/returning
        locationSubject.value = reportedLocation
        return reportedLocation
    }

    func getLocation(
        timeoutSeconds: Double,
        staleSeconds: Double = 60.0
    ) async -> CLLocation? {
        let staleTimeInterval = TimeInterval(max(1.0, staleSeconds))

        if let firstLocation = locationManager.location,
           firstLocation.timestamp.distance(to: Date.now) < staleTimeInterval {
            return firstLocation
        }

        if timeoutSeconds > 0,
           hasLocationAccess {
            do {
                locationManager.requestLocation()

                let timeoutInterval = TimeInterval(timeoutSeconds)
                let pollingStart = Date()
                while pollingStart.distance(to: Date.now) < timeoutInterval {
                    try await Task.sleep(nanoseconds: 300_000_000)

                    if let requestedLocation = locationManager.location,
                       requestedLocation.timestamp.distance(to: Date.now) < staleTimeInterval {
                        return requestedLocation
                    }
                }
            } catch {
                logger.logError(error)
            }
        }

        return nil
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationPermissionSubject.value = status
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        locationSubject.value = location
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        logger.logError(error)
    }
}
