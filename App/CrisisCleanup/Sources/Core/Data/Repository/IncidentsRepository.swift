import Combine
import Foundation

public protocol IncidentsRepository {
    var isLoading: any Publisher<Bool, Never> { get }

    var incidentCount: Int { get }
    var incidents: any Publisher<[Incident], Never> { get }

    var hotlineIncidents: any Publisher<[Incident], Never> { get }

    func getIncident(_ id: Int64, _ loadFormFields: Bool) throws -> Incident?
    func getIncidents(_ startAt: Date) throws -> [Incident]
    func getIncidentsList() async -> [IncidentIdNameType]

    func streamIncident(_ id: Int64) -> any Publisher<Incident?, Never>

    func pullIncidents(force: Bool) async throws
    func pullHotlineIncidents() async

    func pullIncident(_ id: Int64) async throws

    func pullIncidentOrganizations(_ incidentId: Int64, _ force: Bool) async

    func getMatchingIncidents(_ q: String) -> [IncidentIdNameType]
}

extension IncidentsRepository {
    func getIncident(_ id: Int64) throws -> Incident? {
        try getIncident(id, false)
    }

    func pullIncidentOrganizations(_ incidentId: Int64) async {
        await pullIncidentOrganizations(incidentId, false)
    }
}
