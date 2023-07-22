import Combine
import Foundation

internal class CasesMapBoundsManager {
    private let incidentSelector: IncidentSelector
    private let incidentBoundsProvider: IncidentBoundsProvider

    private var mapBoundsCache = MapViewCameraBoundsDefault.bounds

    var centerCache: LatLng { mapBoundsCache.center }

    private let mapCameraBoundsSubject = CurrentValueSubject<MapViewCameraBounds, Never>(MapViewCameraBoundsDefault)
    let mapCameraBoundsPublisher: any Publisher<MapViewCameraBounds, Never>

    let isDeterminingBoundsPublisher: any Publisher<Bool, Never>

    private var incidentIdCache: Int64 = EmptyIncident.id

    private var disposables = Set<AnyCancellable>()

    init(
        _ incidentSelector: IncidentSelector,
        _ incidentBoundsProvider: IncidentBoundsProvider
    ) {
        self.incidentSelector = incidentSelector
        self.incidentBoundsProvider = incidentBoundsProvider

        mapCameraBoundsPublisher = mapCameraBoundsSubject

        let incidentIdPublisher = incidentSelector.incidentId.eraseToAnyPublisher()
        let incidentPublisher = incidentSelector.incident.eraseToAnyPublisher()

        let incidentBoundsPublisher = incidentBoundsProvider.mappingBoundsIncidentIds.eraseToAnyPublisher()

        isDeterminingBoundsPublisher = Publishers.CombineLatest(
            incidentIdPublisher,
            incidentBoundsPublisher)
        .map { id, ids in
            ids.contains(id)
        }

        incidentPublisher
            .map { incident in
                self.incidentIdCache = incident.id
                return self.incidentBoundsProvider.mapIncidentBounds(incident)
            }
            .switchToLatest()
            .sink { incidentBounds in
                if incidentBounds.locations.isNotEmpty {
                    let bounds = incidentBounds.bounds
                    self.mapCameraBoundsSubject.value = MapViewCameraBounds(bounds)
                    self.cacheBounds(bounds)
                }
            }
            .store(in: &disposables)
    }

    func cacheBounds(_ bounds: LatLngBounds) {
        mapBoundsCache = bounds
    }

    func restoreBounds() {
        mapCameraBoundsSubject.value = MapViewCameraBounds(mapBoundsCache, 0)
    }

    func restoreIncidentBounds() {
        let incidentId = incidentIdCache
        if let incidentBounds = incidentBoundsProvider.getIncidentBounds(incidentId) {
            let bounds = incidentBounds.bounds
            let latLngBounds = LatLngBounds(southWest: bounds.southWest, northEast: bounds.northEast)

            mapCameraBoundsSubject.value = MapViewCameraBounds(latLngBounds)
            mapBoundsCache = latLngBounds
        }
    }
}
