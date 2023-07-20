//  Created by Anthony Aguilar on 7/12/23.

import Foundation
import MapKit

class LocationManager: NSObject, ObservableObject {

    private let locationManager = CLLocationManager()
    @Published  var location: CLLocation? = nil

    private let authorizedLocationAccessStatuses: Set<CLAuthorizationStatus> = [
        .authorizedAlways,
        .authorizedWhenInUse
    ]
    private let noLocationAccessStatuses: Set<CLAuthorizationStatus> = [
        .authorizedAlways,
        .authorizedWhenInUse
    ]
    var hasLocationAccess: Bool { authorizedLocationAccessStatuses.contains(locationManager.authorizationStatus) }

    var isDeniedLocationAccess: Bool { noLocationAccessStatuses.contains(locationManager.authorizationStatus) }

    override init(){
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
    }

    func requestLocationAccess() {
        self.locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // TODO: Handle change accordingly as necessary
        print("Location status change \(status)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        self.location = location
    }

}
