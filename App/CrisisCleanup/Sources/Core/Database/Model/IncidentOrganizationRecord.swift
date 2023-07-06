import GRDB

// TODO: Create database tables and related

struct IncidentOrganizationRecord: Identifiable, Equatable {
    let id: Int64
    let name: String
}

extension IncidentOrganizationRecord: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns: String, ColumnExpression {
        case id,
             name
    }
}

struct OrganizationToPrimaryContactRecord: Identifiable, Equatable {
    /// organizationIod
    let id: Int64
    let contactId: Int64
}

extension OrganizationToPrimaryContactRecord: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns: String, ColumnExpression {
        case organizationId,
             contactId
    }
}

struct OrganizationAffiliateRecord: Identifiable, Equatable {
    let id: Int64
    let affiliateId: Int64
}

extension OrganizationAffiliateRecord: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns: String, ColumnExpression {
        case id,
             affiliateId
    }
}
