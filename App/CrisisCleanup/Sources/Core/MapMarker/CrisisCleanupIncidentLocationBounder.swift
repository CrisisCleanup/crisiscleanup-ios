import Atomics
import CoreLocation
import Foundation

class CrisisCleanupIncidentLocationBounder: IncidentLocationBounder {
    private let incidentsRepository: IncidentsRepository
    private let locationsRepository: LocationsRepository
    private let logger: AppLogger

    private let bounderLock = NSLock()
    private var bounderIncidentId = EmptyIncident.id
    private var incidentBounds: IncidentBounds? = nil

    init(
        incidentsRepository: IncidentsRepository,
        locationsRepository: LocationsRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.locationsRepository = locationsRepository
        logger = loggerFactory.getLogger("incident-location")
    }

    private func getBounds(_ incidentId: Int64) async -> IncidentBounds? {
        guard incidentId != EmptyIncident.id else {
            return nil
        }

        var bounds: IncidentBounds? = nil

        bounderLock.withLock {
            if bounderIncidentId == incidentId {
                bounds = incidentBounds
            }
        }

        if bounds == nil {
            do {
                if let locationIds = try incidentsRepository.getIncident(incidentId)?.locationIds,
                   locationIds.isNotEmpty {
                    let locations = locationsRepository.getLocations(ids: locationIds)
                    bounds = try locations.toLatLngs.toIncidentBounds()

                    bounderLock.withLock {
                        bounderIncidentId = incidentId
                        incidentBounds = bounds
                    }
                }
            } catch {
                logger.logError(error)
            }
        }

        return bounds
    }

    func isInBounds(_ incidentId: Int64, latitude: Double, longitude: Double) async -> Bool {
        await getBounds(incidentId)?.containsLocation(LatLng(latitude, longitude)) ?? false
    }

    func getBoundsCenter(_ incidentId: Int64) async -> CLLocation? {
        if let center = await getBounds(incidentId)?.bounds.center {
            return CLLocation(latitude: center.latitude, longitude: center.longitude)
        }

        return nil
    }
}
