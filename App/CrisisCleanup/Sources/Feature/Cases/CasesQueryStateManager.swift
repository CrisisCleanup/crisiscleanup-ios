import Combine
import Foundation

internal class CasesQueryStateManager {
    let isTableViewSubject = CurrentValueSubject<Bool, Never>(false)

    let mapZoomSubject = CurrentValueSubject<Double, Never>(0)

    let mapBoundsSubject = CurrentValueSubject<CoordinateBounds, Never>(CoordinateBoundsDefault)

    let tableViewSort = CurrentValueSubject<WorksiteSortBy, Never>(.none)

    let locationPermission = CurrentValueSubject<Bool, Never>(false)

    private let worksiteQueryStateSubject = CurrentValueSubject<WorksiteQueryState, Never>(WorksiteQueryStateDefault)
    var worksiteQueryState: AnyPublisher<WorksiteQueryState, Never>

    private var disposables = Set<AnyCancellable>()

    init(
        _ incidentSelector: IncidentSelector,
        _ filterRepository: CasesFilterRepository,
        _ mapChangeDebounceTimeout: Double = 0.1
    ) {
        worksiteQueryState = worksiteQueryStateSubject
            .eraseToAnyPublisher()

        incidentSelector.incident
            .sink(receiveValue: { incident in
                self.updateState { $0.incidentId = incident.id }
            })
            .store(in: &disposables)

        isTableViewSubject
            .sink(receiveValue: { b in
                self.updateState { $0.isTableView = b }
            })
            .store(in: &disposables)

        mapZoomSubject
            .throttle(
                for: .seconds(mapChangeDebounceTimeout),
                scheduler: RunLoop.main,
                latest: true
            )
            .sink(receiveValue: { zoom in
                self.updateState { $0.zoom = zoom }
            })
            .store(in: &disposables)

        mapBoundsSubject
            .throttle(
                for: .seconds(mapChangeDebounceTimeout),
                scheduler: RunLoop.main,
                latest: true
            )
            .sink(receiveValue: { bounds in
                self.updateState { $0.coordinateBounds = bounds }
            })
            .store(in: &disposables)

        tableViewSort
            .sink(receiveValue: { sortBy in
                self.updateState { $0.tableViewSort = sortBy }
            })
            .store(in: &disposables)

        filterRepository.casesFiltersLocation
            .sink(receiveValue: { (filters, _, _) in
                self.updateState { $0.filters = filters }
            })
            .store(in: &disposables)

        locationPermission
            .sink(receiveValue: { hasPermission in
                self.updateState { $0.hasLocationPermission = hasPermission }
            })
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func updateState(build: (inout WorksiteQueryState.Builder) -> Void) {
        worksiteQueryStateSubject.value = worksiteQueryStateSubject.value.copy(build: build)
    }
}
