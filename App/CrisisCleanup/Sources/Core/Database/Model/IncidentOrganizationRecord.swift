import Foundation
import GRDB

struct IncidentOrganizationRecord: Identifiable, Equatable {
    static let primaryContacts = hasMany(
        PersonContactRecord.self,
        through: hasMany(OrganizationToPrimaryContactRecord.self),
        using: OrganizationToPrimaryContactRecord.personContacts
    )
    static let organizationAffiliates = hasMany(OrganizationAffiliateRecord.self)

    let id: Int64
    let name: String
    let primaryLocation: Int64?
    let secondaryLocation: Int64?
}

extension IncidentOrganizationRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentOrganization"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             name,
             primaryLocation,
             secondaryLocation
    }

    static let idColumn: [SQLSelectable] = [Columns.id]
    static let locationColumns: [SQLSelectable] = [
        Columns.primaryLocation,
        Columns.secondaryLocation,
    ]
}

extension DerivableRequest<IncidentOrganizationRecord> {
    func inIds(_ ids: [Int64]) -> Self {
        filter(ids.contains(IncidentOrganizationRecord.Columns.id))
    }

    func byId(_ id: Int64) -> Self {
        filter(IncidentOrganizationRecord.Columns.id == id)
    }
}

// MARK: Organization to primary contact

struct OrganizationToPrimaryContactRecord: Identifiable, Equatable {
    static let personContacts = belongsTo(PersonContactRecord.self)
    static let organization = belongsTo(IncidentOrganizationRecord.self)

    /// organizationIod
    let id: Int64
    let contactId: Int64
}

extension OrganizationToPrimaryContactRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "organizationToPrimaryContact"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             contactId
    }

    static func deleteInIds(
        _ db: Database,
        _ ids: Set<Int64>
    ) throws {
        try OrganizationToPrimaryContactRecord
            .filter(ids.contains(Columns.id))
            .deleteAll(db)
    }
}

// MARK: Organization to affiliate

struct OrganizationAffiliateRecord: Identifiable, Equatable {
    static let organization = belongsTo(IncidentOrganizationRecord.self)

    let id: Int64
    let affiliateId: Int64
}

extension OrganizationAffiliateRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "organizationAffiliate"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             affiliateId
    }

    static func deleteInIds(
        _ db: Database,
        _ ids: Set<Int64>
    ) throws {
        try OrganizationAffiliateRecord
            .filter(ids.contains(Columns.id))
            .deleteAll(db)
    }
}

extension DerivableRequest<OrganizationAffiliateRecord> {
    func byId(_ organizationId: Int64) -> Self {
        filter(OrganizationAffiliateRecord.Columns.id == organizationId)
    }
}

// MARK: Organization sync stats

struct IncidentOrganizationSyncStatRecord : Identifiable, Equatable {
    let id: Int64
    let targetCount: Int
    let successfulSync: Date?
    let appBuildVersionCode: Int64

    func asExternalModel() -> IncidentDataSyncStats {
        IncidentDataSyncStats(
            incidentId: id,
            syncStart: Date.now,
            dataCount: targetCount,
            pagedCount: targetCount,
            syncAttempt: SyncAttempt(
                successfulSeconds: successfulSync?.timeIntervalSince1970 ?? 0.0,
                attemptedSeconds: 0.0,
                attemptedCounter: 0
            ),
            appBuildVersionCode: appBuildVersionCode
        )
    }
}

extension IncidentOrganizationSyncStatRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentOrganizationSyncStat"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             targetCount,
             successfulSync,
             appBuildVersionCode
    }
}

extension DerivableRequest<IncidentOrganizationSyncStatRecord> {
    func byId(_ incidentId: Int64) -> Self {
        filter(IncidentOrganizationSyncStatRecord.Columns.id == incidentId)
    }
}
