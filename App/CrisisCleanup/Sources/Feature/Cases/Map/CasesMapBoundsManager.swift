import Combine
import CombineExt
import Foundation
import MapKit

internal class CasesMapBoundsManager {
    private let incidentSelector: IncidentSelector
    private let incidentBoundsProvider: IncidentBoundsProvider
    private let preferencesDataSource: AppPreferencesDataSource

    private var mapBoundsCache = MapViewCameraBoundsDefault.bounds

    var centerCache: LatLng { mapBoundsCache.center }

    private let mapCameraBoundsSubject = CurrentValueSubject<MapViewCameraBounds, Never>(MapViewCameraBoundsDefault)
    let mapCameraBoundsPublisher: any Publisher<MapViewCameraBounds, Never>

    private var incidentIdCache = EmptyIncident.id
    let incidentBoundsPublisher: any Publisher<LatLngBounds, Never>

    let isDeterminingBoundsPublisher: any Publisher<Bool, Never>

    private let mapLoadTime = Date.now

    private var isStarted: Bool {
        mapLoadTime.distance(to: Date.now) > 2.seconds
    }

    private let saveIncidentMapBoundsPublisher = CurrentValueSubject<IncidentCoordinateBounds, Never>(IncidentCoordinateBoundsNone)

    private var disposables = Set<AnyCancellable>()

    init(
        _ incidentSelector: IncidentSelector,
        _ incidentBoundsProvider: IncidentBoundsProvider,
        _ preferencesDataSource: AppPreferencesDataSource
    ) {
        self.incidentSelector = incidentSelector
        self.incidentBoundsProvider = incidentBoundsProvider
        self.preferencesDataSource = preferencesDataSource

        mapCameraBoundsPublisher = mapCameraBoundsSubject

        let incidentIdPublisher = incidentSelector.incidentId.eraseToAnyPublisher()
        let incidentPublisher = incidentSelector.incident.eraseToAnyPublisher()

        let mappingBoundsIncidentIds = incidentBoundsProvider.mappingBoundsIncidentIds.eraseToAnyPublisher()

        isDeterminingBoundsPublisher = Publishers.CombineLatest(
            incidentIdPublisher,
            mappingBoundsIncidentIds
        )
        .map { id, ids in
            ids.contains(id)
        }

        let zeroBounds = LatLngBounds(
            southWest: LatLng(0.0, 0.0),
            northEast: LatLng(0.0, 0.0)
        )

        incidentBoundsPublisher = incidentPublisher
            .flatMapLatest { incident in
                incidentBoundsProvider.mapIncidentBounds(incident)
            }
            .map { incidentBounds in
                return if incidentBounds.locations.isEmpty {
                    zeroBounds
                } else {
                    incidentBounds.bounds
                }
            }
            .removeDuplicates()
            .replay1()

        incidentIdPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.incidentIdCache, on: self)
            .store(in: &disposables)

        let savedBounds = Publishers.CombineLatest(
            incidentIdPublisher,
            preferencesDataSource.preferences.eraseToAnyPublisher()
        )
            .map { (incidentId, preferences) in
                return if let mapBounds = preferences.casesMapBounds,
                          incidentId != EmptyIncident.id,
                          incidentId == mapBounds.incidentId {
                    mapBounds.latLngBounds
                } else {
                    zeroBounds
                }
            }

        // Starting bounds
        Publishers.CombineLatest(
            incidentBoundsPublisher.eraseToAnyPublisher(),
            savedBounds
        )
        .throttle(
            for: .seconds(1),
            scheduler: RunLoop.current,
            latest: true
        )
        .receive(on: RunLoop.main)
        .sink { (ib, sb) in
            let bounds = if self.isStarted {
                zeroBounds
            } else {
                if sb != zeroBounds {
                    sb
                } else if ib != zeroBounds {
                    ib
                } else {
                    zeroBounds
                }
            }
            if bounds != zeroBounds {
                self.cacheBounds(bounds, cacheToDisk: false)
                self.mapCameraBoundsSubject.value = MapViewCameraBounds(bounds, 0)
            }
        }
        .store(in: &disposables)

        // Incident change bounds
        incidentBoundsPublisher
            .eraseToAnyPublisher()
            .debounce(for: .seconds(0.1), scheduler: RunLoop.current)
            .receive(on: RunLoop.main)
            .sink { ib in
                if self.isStarted,
                   ib != zeroBounds {
                    self.cacheBounds(ib, cacheToDisk: true)
                    self.mapCameraBoundsSubject.value = MapViewCameraBounds(ib)
                }
            }
            .store(in: &disposables)

        saveIncidentMapBoundsPublisher
        .filter { $0 != IncidentCoordinateBoundsNone}
        .throttle(
            for: .seconds(0.6),
            scheduler: RunLoop.current,
            latest: true
        )
        .sink { bounds in
            Task {
                self.preferencesDataSource.setCasesMapBounds(bounds)
            }
        }
        .store(in: &disposables)
    }

    func unsubscribe() {
        _ = cancelSubscriptions(disposables)
    }

    private func cacheBounds(_ bounds: LatLngBounds, cacheToDisk: Bool) {
        if bounds == mapBoundsCache {
            return
        }

        mapBoundsCache = bounds

        if isStarted,
           cacheToDisk {
            saveIncidentMapBoundsPublisher.value = bounds.asIncidentCoordinateBounds(incidentIdCache)
        }
    }

    func cacheBounds(_ bounds: LatLngBounds) {
        cacheBounds(bounds, cacheToDisk: isStarted)
    }

    func restoreBounds() {
        mapCameraBoundsSubject.value = MapViewCameraBounds(mapBoundsCache, 0)
    }

    func restoreIncidentBounds() {
        let incidentId = incidentIdCache
        if let incidentBounds = incidentBoundsProvider.getIncidentBounds(incidentId) {
            mapCameraBoundsSubject.value = MapViewCameraBounds(incidentBounds.bounds)
        }
    }
}

extension IncidentCoordinateBounds {
    var latLngBounds: LatLngBounds {
        return LatLngBounds(
            southWest: LatLng(south, west),
            northEast: LatLng(north, east)
        )
    }
}
