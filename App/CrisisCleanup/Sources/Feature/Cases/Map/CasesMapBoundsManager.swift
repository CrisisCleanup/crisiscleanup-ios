import Combine
import Foundation

internal class CasesMapBoundsManager {
    private let incidentSelector: IncidentSelector
    private let incidentBoundsProvider: IncidentBoundsProvider

    private var mapBoundsCache = MapViewCameraBoundsDefault.bounds

    var centerCache: LatLng { mapBoundsCache.center }

    @Published private(set) var mapCameraBounds = MapViewCameraBoundsDefault
    private lazy var mapCameraBoundsPublisher = $mapCameraBounds

    @Published private(set) var isDeterminingBounds = false

    @Published private(set) var incidentIdCache: Int64 = EmptyIncident.id

    @Published private var incidentIdBounds = DefaultIncidentBounds
    private lazy var incidentIdBoundsPublisher = $incidentIdBounds

    private var disposables = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentBoundsProvider: IncidentBoundsProvider
    ) {
        self.incidentSelector = incidentSelector
        self.incidentBoundsProvider = incidentBoundsProvider

        incidentSelector.incident
            .eraseToAnyPublisher()
            .map { incident in
                self.incidentIdCache = incident.id
                return self.incidentBoundsProvider.mapIncidentBounds(incident)
            }
            .switchToLatest()
            .assign(to: &self.incidentIdBoundsPublisher)

        incidentIdBoundsPublisher
            .receive(on: RunLoop.main)
            .sink { incidentBounds in
                if (incidentBounds.locations.isNotEmpty) {
                    let bounds = incidentBounds.bounds
                    self.mapCameraBounds = MapViewCameraBounds(bounds)
                    self.cacheBounds(bounds)
                }
            }
            .store(in: &disposables)

        incidentSelector.incidentId.combineLatest(
            incidentBoundsProvider.mappingBoundsIncidentIds, { id, ids in
                ids.contains(id)
            })
        .sink(receiveValue: { isMappingBounds in
            self.isDeterminingBounds = isMappingBounds
        })
        .store(in: &disposables)
    }

    func cacheBounds(_ bounds: LatLngBounds) {
        mapBoundsCache = bounds
    }

    func restoreBounds() {
        mapCameraBounds = MapViewCameraBounds(mapBoundsCache, 0)
    }

    func restoreIncidentBounds() {
        let incidentId = incidentIdCache
        if let incidentBounds = incidentBoundsProvider.getIncidentBounds(incidentId) {
            let bounds = incidentBounds.bounds
            let latLngBounds = LatLngBounds(southWest: bounds.southWest, northEast: bounds.northEast)

            mapCameraBounds = MapViewCameraBounds(latLngBounds)
            mapBoundsCache = latLngBounds
        }
    }
}
