class CrisisCleanupLocationBoundsConverter: LocationBoundsConverter {
    private let logger: AppLogger

    init(loggerFactory: AppLoggerFactory) {
        logger = loggerFactory.getLogger("location-bounds-converter")
    }

    func convert(_ location: Location) -> LocationAreaBounds {
        do {
            let incidentBounds = try [location].toLatLngs.toIncidentBounds()
            return LocationIncidentAreaBounds(incidentBounds)
        } catch {
            logger.logError(error)
        }
        return NoAreaBounds()
    }
}

private struct LocationIncidentAreaBounds: LocationAreaBounds {
    private let incidentBounds: IncidentBounds

    init(_ incidentBounds: IncidentBounds) {
        self.incidentBounds = incidentBounds
    }

    func isInBounds(_ latitude: Double, _ longitude: Double) -> Bool {
        let latLng = LatLng(latitude, longitude)
        return incidentBounds.containsLocation(latLng)
    }
}

private struct NoAreaBounds: LocationAreaBounds {
    func isInBounds(_ latitude: Double, _ longitude: Double) -> Bool {
        false
    }
}
