import Combine
import CoreLocation

public protocol IncidentMapTracker {
    var lastLocation: any Publisher<IncidentMapCoordinates, Never> { get }
}

class AppIncidentMapTracker: IncidentMapTracker {
    let lastLocation: any Publisher<IncidentMapCoordinates, Never>

    init(
        preferenceDataSource: AppPreferencesDataStore
    ) {
        lastLocation = preferenceDataSource.preferences
            .eraseToAnyPublisher()
            .map { prefs in
                var mapIncident = EmptyIncident.id
                var latitude = 0.0
                var longitude = 0.0
                with(prefs.casesMapBounds) { mapBounds in
                    if let mapBounds = mapBounds,
                       mapBounds.incidentId > 0,
                       mapBounds.south < mapBounds.north,
                       mapBounds.west < mapBounds.east {
                        latitude = (mapBounds.south + mapBounds.north) * 0.5
                        longitude = (mapBounds.west + mapBounds.east) * 0.5
                        if -90 <= latitude,
                            latitude <= 90,
                            -180 <= longitude,
                            longitude <= 180 {
                            mapIncident = mapBounds.incidentId
                        } else {
                            latitude = 0.0
                            longitude = 0.0
                        }
                    }
                }
                return IncidentMapCoordinates(
                    incidentId: mapIncident,
                    latitude: latitude,
                    longitude: longitude
                )
            }
            .removeDuplicates()
    }
}
