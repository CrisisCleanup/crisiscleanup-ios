public struct IncidentOrganization {
    let id: Int64
    let name: String
    let primaryContacts: [PersonContact]
    let affiliateIds: Set<Int64>
}

struct OrganizationIdName {
    let id: Int64
    let name: String
}

extension Array where Element == OrganizationIdName {
    func asLookup() -> [Int64: String] {
        associate { ($0.id, $0.name) }
    }
}
