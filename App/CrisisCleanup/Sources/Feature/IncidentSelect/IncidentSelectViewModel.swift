import SwiftUI
import Combine

class IncidentSelectViewModel: ObservableObject {
    @Published private(set) var incidentsData = LoadingIncidentsData

    let incidentSelector: IncidentSelector

    private var disposables = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector
    ) {
        self.incidentSelector = incidentSelector

        incidentSelector.incidentsData.sink { self.incidentsData = $0 }
            .store(in: &disposables)
    }
}
