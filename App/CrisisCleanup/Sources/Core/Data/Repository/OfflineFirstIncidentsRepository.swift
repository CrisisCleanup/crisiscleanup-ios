import Combine
import Foundation

class OfflineFirstIncidentsRepository: IncidentsRepository {
    @Published private var isLoadingStream = false
    lazy var isLoading = $isLoadingStream

    @Published private var incidentsStream: [Incident] = []
    lazy var incidents = $incidentsStream

    private var incidentPublisher = Just<Incident?>(nil)

    init() {

    }

    func getIncidents(_ startAt: Date) async -> [Incident] {
        // TODO: Do
        return []
    }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) async -> Incident? {
        // TODO: Do
        return nil
    }

    func streamIncident(_ id: Int64) -> AnyPublisher<Incident?, Never> {
        // TODO: Do
        return incidentPublisher.eraseToAnyPublisher()
    }

    func pullIncidents() async {
        // TODO: Do
    }

    func pullIncident(id: Int64) async {
        // TODO: Do
    }

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async {
        // TODO: Do
    }
}
