import Combine
import CoreLocation
import Foundation

public protocol IncidentBoundsProvider {
    var mappingBoundsIncidentIds: any Publisher<Set<Int64>, Never> { get }

    func mapIncidentBounds(_ incident: Incident) -> AnyPublisher<IncidentBounds, Never>

    func getIncidentBounds(_ incidentId: Int64) -> IncidentBounds?

    func isInRecentIncidentBounds(_ coordintes: LatLng) throws -> Incident?
}

class MapsIncidentBoundsProvider: IncidentBoundsProvider {
    private let incidentsRepository: IncidentsRepository
    private let locationsRepository: LocationsRepository

    private let staleDuration: TimeInterval
    private var cache: [Int64: CacheEntry]

    private let incidentIdsPublisher = CurrentValueSubject<Set<Int64>, Never>(Set())
    let mappingBoundsIncidentIds: any Publisher<Set<Int64>, Never>

    init(
        incidentsRepository: IncidentsRepository,
        locationsRepository: LocationsRepository,
        staleDuration: TimeInterval = 3.hours
    ) {
        self.incidentsRepository = incidentsRepository
        self.locationsRepository = locationsRepository
        self.staleDuration = staleDuration
        self.cache = [Int64: CacheEntry]()

        mappingBoundsIncidentIds = incidentIdsPublisher
    }

    func getIncidentBounds(_ incidentId: Int64) -> IncidentBounds? { cache[incidentId]?.bounds }

    private func publishIds(_ id: Int64, _ add: Bool) {
        var copyIds = Set(incidentIdsPublisher.value)
        if add {
            copyIds.insert(id)
        } else {
            copyIds.remove(id)
        }
        incidentIdsPublisher.send(copyIds)
    }

    private func cacheIncidentBounds(
        _ incidentId: Int64,
        _ locations: [Location],
        _ locationIds: Set<Int64>
    ) throws -> IncidentBounds {
        publishIds(incidentId, true)
        do {
            defer { publishIds(incidentId, false) }

            let incidentBounds = try locations.toLatLngs.toIncidentBounds()
            self.cache[incidentId] = CacheEntry(
                bounds: incidentBounds,
                locationIds: locationIds,
                timestamp: Date()
            )

            return incidentBounds
        }
    }

    func mapIncidentBounds(_ incident: Incident) -> AnyPublisher<IncidentBounds, Never> {
        let incidentId = incident.id
        let locationIds = incident.locationIds
        if incidentId == EmptyIncident.id || locationIds.isEmpty {
            return Just(DefaultIncidentBounds)
                .eraseToAnyPublisher()
        } else {
            let locationsStream = locationsRepository.streamLocations(locationIds)
            return locationsStream.map { locations in
                do {
                    return try self.cacheIncidentBounds(incidentId, locations, Set(locationIds))
                } catch {
                    // TODO: Return previous value not a default value
                    return DefaultIncidentBounds
                }
            }
            .assertNoFailure()
            .eraseToAnyPublisher()
        }
    }

    func isInRecentIncidentBounds(_ coordinates: LatLng) throws -> Incident? {
        let startAt = Date().addingTimeInterval(-60.days)
        let recentIncidents = try incidentsRepository.getIncidents(startAt)
        for incident in recentIncidents {
            if !cache.keys.contains(incident.id) {
                let locationIds = incident.locationIds
                let locations = locationsRepository.getLocations(ids: locationIds)
                _ = try cacheIncidentBounds(incident.id, locations, Set(locationIds))
            }
            if let cached = cache[incident.id] {
                if cached.bounds.containsLocation(coordinates) {
                    return incident
                }
            }
        }
        return nil
    }
}

private struct CacheEntry {
    let bounds: IncidentBounds
    let locationIds: Set<Int64>
    let timestamp: Date
}
