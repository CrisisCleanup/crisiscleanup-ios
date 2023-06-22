import Combine
import Foundation

internal class CasesQueryStateManager {
    let isTableViewSubject = CurrentValueSubject<Bool, Never>(false)

    let mapZoomSubject = CurrentValueSubject<Double, Never>(0)

    let mapBoundsSubject = CurrentValueSubject<CoordinateBounds, Never>(CoordinateBoundsDefault)

    private let worksiteQueryStateSubject = CurrentValueSubject<WorksiteQueryState, Never>(WorksiteQueryStateDefault)
    var worksiteQueryState: any Publisher<WorksiteQueryState, Never>

    private var disposables = Set<AnyCancellable>()

    init(
        _ incidentSelector: IncidentSelector,
        _ mapChangeDebounceTimeout: Double = 0.1
    ) {
        worksiteQueryState = worksiteQueryStateSubject

        incidentSelector.incident
            .sink { completion in
            } receiveValue: { incident in
                self.updateState { $0.incidentId = incident.id }
            }
            .store(in: &disposables)

        isTableViewSubject
            .sink(receiveCompletion: { completion in
            }, receiveValue: { b in
                self.updateState { $0.isTableView = b }
            })
            .store(in: &disposables)

        mapZoomSubject
            .debounce(
                for: .seconds(mapChangeDebounceTimeout),
                scheduler: RunLoop.main
            )
            .sink(receiveCompletion: { completion in
            }, receiveValue: { zoom in
                self.updateState { $0.zoom = zoom }
            })
            .store(in: &disposables)

        mapBoundsSubject
            .debounce(
                for: .seconds(mapChangeDebounceTimeout),
                scheduler: RunLoop.main
            )
            .sink(receiveCompletion: { completion in
            }, receiveValue: { bounds in
                self.updateState { $0.coordinateBounds = bounds }
            })
            .store(in: &disposables)
    }

    private func updateState(build: (inout WorksiteQueryState.Builder) -> Void) {
        worksiteQueryStateSubject.value = worksiteQueryStateSubject.value.copy(build: build)
    }
}
