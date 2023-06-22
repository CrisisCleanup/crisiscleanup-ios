import Combine
import Foundation

public protocol IncidentsRepository {
    var isLoading: any Publisher<Bool, Never> { get }

    var incidents: any Publisher<[Incident], Never> { get }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) throws -> Incident?
    func getIncidents(_ startAt: Date) throws -> [Incident]

    func streamIncident(_ id: Int64) -> any Publisher<Incident?, Never>

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
