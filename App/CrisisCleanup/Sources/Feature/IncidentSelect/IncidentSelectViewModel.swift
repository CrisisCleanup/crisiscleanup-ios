import SwiftUI
import Combine

class IncidentSelectViewModel: ObservableObject {
    let incidentSelector: IncidentSelector

    @Published private(set) var incidentsData = LoadingIncidentsData

    @Published private(set) var selectedIncidentId :Int64 = -1
    private var isFocusedOnSelected = false

    private var isOptionsRendered = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector
    ) {
        self.incidentSelector = incidentSelector
    }

    func onViewAppear() {
        subscribeToIncidents()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    func onOptionsRendered() {
        isOptionsRendered = true
        setSelectedIncident()
    }

    private func subscribeToIncidents() {
        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)

        $incidentsData
            .map { $0.selectedId }
            .filter{ $0 > 0 }
            .receive(on: RunLoop.main)
            .sink { selectedId in
                self.setSelectedIncident()
            }
            .store(in: &subscriptions)
    }

    private func setSelectedIncident() {
        if isOptionsRendered &&
            incidentsData.selectedId > 0 &&
            !isFocusedOnSelected {
            isFocusedOnSelected = true
            selectedIncidentId = incidentsData.selectedId
        }
    }
}
