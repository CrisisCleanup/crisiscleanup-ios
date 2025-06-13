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
        _ appPreferences: AppPreferencesDataSource,
        _ mapChangeDebounceTimeout: Double = 0.1
    ) {
        worksiteQueryState = worksiteQueryStateSubject
            .eraseToAnyPublisher()

        incidentSelector.incident
            .sink { incident in
                self.updateState { $0.incidentId = incident.id }
            }
            .store(in: &disposables)

        isTableViewSubject
            .sink { b in
                self.updateState { $0.isTableView = b }
            }
            .store(in: &disposables)

        mapZoomSubject
            .throttle(
                for: .seconds(mapChangeDebounceTimeout),
                scheduler: RunLoop.main,
                latest: true
            )
            .sink { zoom in
                self.updateState { $0.zoom = zoom }
            }
            .store(in: &disposables)

        mapBoundsSubject
            .throttle(
                for: .seconds(mapChangeDebounceTimeout),
                scheduler: RunLoop.main,
                latest: true
            )
            .sink { bounds in
                self.updateState { $0.coordinateBounds = bounds }
            }
            .store(in: &disposables)

        tableViewSort
            .sink { sortBy in
                self.updateState { $0.tableViewSort = sortBy }
            }
            .store(in: &disposables)

        filterRepository.casesFiltersLocation
            .sink { (filters, _, _) in
                self.updateState { $0.filters = filters }
            }
            .store(in: &disposables)

        locationPermission
            .sink { hasPermission in
                self.updateState { $0.hasLocationPermission = hasPermission }
            }
            .store(in: &disposables)

        Task {
            do {
                let preferencesPublisher = appPreferences.preferences.eraseToAnyPublisher()
                let cached = try await preferencesPublisher.asyncFirst()
                let isTableViewCached = cached.isWorkScreenTableView ?? false
                if isTableViewCached != self.isTableViewSubject.value {
                    self.isTableViewSubject.value = isTableViewCached
                }
            } catch {}
        }
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func updateState(build: (inout WorksiteQueryState.Builder) -> Void) {
        worksiteQueryStateSubject.value = worksiteQueryStateSubject.value.copy(build: build)
    }
}
