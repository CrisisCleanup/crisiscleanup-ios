import SwiftUI
import Combine

class CasesViewModel: ObservableObject {
    private let incidentSelector: IncidentSelector
    private let logger: AppLogger

    @Published var profilePicture: AccountProfilePicture? = nil

    @Published private(set) var incidentsData = LoadingIncidentsData

    private var disposables = Set<AnyCancellable>()

    init(
        incidentSelector: IncidentSelector,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentSelector = incidentSelector
        logger = loggerFactory.getLogger("cases")

        incidentSelector.incidentsData.sink { self.incidentsData = $0 }
            .store(in: &disposables)
    }
}

struct AccountProfilePicture {
    let url: URL
    let isSvg: Bool
}
