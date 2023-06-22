import SwiftUI
import Combine

class CasesViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let logger: AppLogger

    @Published private(set) var incidentsData = LoadingIncidentsData

    private let mapBoundsManager: CasesMapBoundsManager

    @Published private(set) var incidentLocationBounds = MapViewCameraBoundsDefault
    private lazy var incidentLocationBoundsPublisher = $incidentLocationBounds

    @Published private(set) var isMapBusy: Bool = false

    private var disposables = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        incidentBoundsProvider: IncidentBoundsProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentSelector = incidentSelector
        mapBoundsManager = CasesMapBoundsManager(
            incidentSelector,
            incidentBoundsProvider
        )
        logger = loggerFactory.getLogger("cases")

        incidentSelector.incidentsData.sink { self.incidentsData = $0 }
            .store(in: &disposables)

        mapBoundsManager.mapCameraBoundsPublisher
            .eraseToAnyPublisher()
            .assign(to: &incidentLocationBoundsPublisher)

        mapBoundsManager.isDeterminingBoundsPublisher
            .sink { b0 in
                self.isMapBusy = b0
            }
            .store(in: &disposables)
    }

    func onViewAppear() {
        // TODO: Resume observations
    }

    func onViewDisappear() {
        // TODO: Pause observations
    }
}
