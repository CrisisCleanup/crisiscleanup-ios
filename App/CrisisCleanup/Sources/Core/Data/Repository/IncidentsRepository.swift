import Combine
import Foundation

public protocol IncidentsRepository {
    var isLoading: Published<Bool>.Publisher { get }

    var incidents: Published<[Incident]>.Publisher { get }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) throws -> Incident?
    func getIncidents(_ startAt: Date) throws -> [Incident]

    func streamIncident(_ id: Int64) -> AnyPublisher<Incident?, Error>

    func pullIncidents() async throws

    func pullIncident(_ id: Int64) async throws

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async throws
}

extension IncidentsRepository {
    func getIncident(_ id: Int64) throws -> Incident? {
        try getIncident(id, false)
    }

    func pullIncidentOrganizations(_ incidentId: Int64) async throws {
        try await pullIncidentOrganizations(incidentId, false)
    }
}
