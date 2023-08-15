//  Created by Anthony Aguilar on 7/12/23.

import Foundation
import MapKit

public class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published private(set) var locationPermission: CLAuthorizationStatus? = nil

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

    override init(){
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone

        locationPermission = locationManager.authorizationStatus
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
        location = locationManager.location
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
        self.location = location
    }
}
