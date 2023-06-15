import Combine
import Foundation

public protocol IncidentsRepository {
    var isLoading: Published<Bool>.Publisher { get }

    var incidents: Published<[Incident]>.Publisher { get }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) async -> Incident?
    func getIncidents(_ startAt: Date) async -> [Incident]

    func streamIncident(_ id: Int64) -> AnyPublisher<Incident?, Never>

    func pullIncidents() async throws

    func pullIncident(id: Int64) async

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async
}

extension IncidentsRepository {
    func getIncident(_ id: Int64) async -> Incident? {
        return await getIncident(id, false)
    }

    func pullIncidentOrganizations(_ incidentId: Int64) async {
        await pullIncidentOrganizations(incidentId, false)
    }
}
