//  Created by Anthony Aguilar on 7/12/23.

import Combine
import Foundation
import MapKit

public class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

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
    var hasLocationAccess: Bool { authorizedLocationAccessStatuses.contains(locationManager.authorizationStatus) }

    var isDeniedLocationAccess: Bool { noLocationAccessStatuses.contains(locationManager.authorizationStatus) }

    private var subscriptions = Set<AnyCancellable>()

    override init(){
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone

        locationPermission = locationManager.authorizationStatus

        locationSubject
            .receive(on: RunLoop.main)
            .assign(to: \.location, on: self)
            .store(in: &subscriptions)
    }

    func requestLocationAccess() -> Bool {
        if hasLocationAccess || isDeniedLocationAccess {
            locationPermission = locationManager.authorizationStatus
        } else {
            locationPermission = nil
            self.locationManager.requestWhenInUseAuthorization()
        }
        return hasLocationAccess
    }

    func getLocation() -> CLLocation? {
        locationSubject.value = locationManager.location
        return location
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationPermission = status
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        locationSubject.value = location
    }
}
