import Combine
import Foundation

public protocol IncidentsRepository {
    var isLoading: Published<Bool>.Publisher { get }

    var incidents: Published<[Incident]>.Publisher { get }

    func getIncident(id: Int64) async -> Incident?
    func getIncident(id: Int64, loadFormFields: Bool) async -> Incident?
    func getIncidents(startAt: Date) async -> [Incident]

    func streamIncident(id: Int64) -> Published<Incident?>.Publisher

    func pullIncidents() async

    func pullIncident(id: Int64) async

    func pullIncidentOrganizations(incidentId: Int64) async
    func pullIncidentOrganizations(incidentId: Int64, force: Bool) async
}
