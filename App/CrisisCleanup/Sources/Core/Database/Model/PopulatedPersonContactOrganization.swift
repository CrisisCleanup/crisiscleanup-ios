import GRDB

struct PopulatedPersonContactOrganization: Equatable, Decodable, FetchableRecord {
    let personContact: PersonContactRecord
    let incidentOrganization: IncidentOrganizationRecord?
}
