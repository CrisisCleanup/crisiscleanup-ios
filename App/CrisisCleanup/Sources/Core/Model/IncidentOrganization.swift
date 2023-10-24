public struct IncidentOrganization: Equatable {
    public static func == (lhs: IncidentOrganization, rhs: IncidentOrganization) -> Bool {
        lhs.id == rhs.id
    }

    let id: Int64
    let name: String
    let primaryContacts: [PersonContact]
    let affiliateIds: Set<Int64>
}

let EmptyIncidentOrganization = IncidentOrganization(
    id: EmptyIncident.id,
    name: "",
    primaryContacts: [],
    affiliateIds: []
)

public struct OrganizationIdName: Identifiable {
    public let id: Int64
    let name: String
}

extension Array where Element == OrganizationIdName {
    func asLookup() -> [Int64: String] {
        associate { ($0.id, $0.name) }
    }
}
