import Combine
import Foundation
import GRDB

public class IncidentOrganizationDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func streamOrganizationNames() -> AnyPublisher<[OrganizationIdName], Error> {
        ValueObservation
            .tracking(fetchOrganizationsIdName(_:))
            .removeDuplicates()
            .publisher(in: reader)
            .map {
                $0.map { record in OrganizationIdName(id: record.id, name: record.name) }
            }
            .share()
            .eraseToAnyPublisher()
    }

    private func fetchOrganizationsIdName(_ db: Database) throws -> [IncidentOrganizationRecord] {
        try IncidentOrganizationRecord.fetchAll(db)
    }

    func streamOrganizations() -> AnyPublisher<[PopulatedIncidentOrganization], Error> {
        ValueObservation
            .tracking(fetchOrganizations(_:))
            .removeDuplicates()
            .publisher(in: reader)
            .share()
            .eraseToAnyPublisher()
    }

    private func fetchOrganizations(_ db: Database) throws -> [PopulatedIncidentOrganization] {
        return try IncidentOrganizationRecord
            .including(all: IncidentOrganizationRecord.primaryContacts)
            .including(all: IncidentOrganizationRecord.organizationAffiliates)
            .asRequest(of: PopulatedIncidentOrganization.self)
            .fetchAll(db)
    }

    func getAffiliateOrganizationIds(_ organizationId: Int64) -> [Int64] {
        try! reader.read { db in
            try OrganizationAffiliateRecord
                .all()
                .byId(organizationId)
                .fetchAll(db)
        }
        .map { $0.affiliateId }
    }

    func saveOrganizations(
        _ organizations: [IncidentOrganizationRecord],
        _ primaryContacts: [PersonContactRecord]
    ) async throws {
        try await database.saveOrganizations(organizations, primaryContacts)
    }

    func saveOrganizationReferences(
        _ organizations: [IncidentOrganizationRecord],
        _ organizationContactCrossRefs: [OrganizationToPrimaryContactRecord],
        _ organizationAffiliates: [OrganizationAffiliateRecord]
    ) async throws {
        try await database.saveOrganizationReferences(organizations, organizationContactCrossRefs, organizationAffiliates)
    }

    func getOrganizations(_ organizationIds: [Int64]) throws -> [PopulatedIncidentOrganization] {
        try reader.read { db in
            try IncidentOrganizationRecord
                .select(IncidentOrganizationRecord.inIds(ids: organizationIds))
                .fetchAll(db)
        }
    }

    func getSyncStats(_ incidentId: Int64) throws -> IncidentOrganizationSyncStatRecord? {
        try reader.read { db in
            try IncidentOrganizationSyncStatRecord
                .all()
                .byId(incidentId)
                .fetchOne(db)
        }
    }

    func upsertStats(_ stats: IncidentOrganizationSyncStatRecord) async throws {
        try await database.upsertIncidentOrganizationSyncStats(stats)
    }
}

extension AppDatabase {
    fileprivate func saveOrganizations(
        _ organizations: [IncidentOrganizationRecord],
        _ primaryContacts: [PersonContactRecord]
    ) async throws {
        try await dbWriter.write { db in
            for record in organizations {
                try record.upsert(db)
            }
            for record in primaryContacts {
                try record.upsert(db)
            }
        }
    }

    fileprivate func saveOrganizationReferences(
        _ organizations: [IncidentOrganizationRecord],
        _ organizationContactCrossRefs: [OrganizationToPrimaryContactRecord],
        _ organizationAffiliates: [OrganizationAffiliateRecord]
    ) async throws {
        let organizationIds = Set(organizations.map { $0.id })
        // TODO: Test coverage. Only specified organization data is deleted and updated.
        try await dbWriter.write { db in
            try OrganizationToPrimaryContactRecord
                .all()
                .inIds(organizationIds)
                .deleteAll(db)
            for record in organizationContactCrossRefs {
                try record.insert(db, onConflict: .ignore)
            }
            try OrganizationAffiliateRecord
                .all()
                .inIds(organizationIds)
                .deleteAll(db)
            for record in organizationAffiliates {
                try record.insert(db, onConflict: .ignore)
            }
        }
    }

    fileprivate func upsertIncidentOrganizationSyncStats(
        _ stats: IncidentOrganizationSyncStatRecord
    ) async throws {
        try await dbWriter.write { db in
            try stats.upsert(db)
        }
    }
}

struct PopulatedIncidentOrganization: Equatable, Decodable, FetchableRecord {
    let incidentOrganization: IncidentOrganizationRecord
    // Changing the name will affect deserialization. Modify accordingly.
    let personContacts: [PersonContactRecord]
    let organizationAffiliates: [OrganizationAffiliateRecord]

    func asExternalModel() -> IncidentOrganization {
        var affiliateIds: Set<Int64> = [incidentOrganization.id]
        organizationAffiliates.forEach { record in
            affiliateIds.insert(record.affiliateId)
        }
        return IncidentOrganization(
            id: incidentOrganization.id,
            name: incidentOrganization.name,
            primaryContacts: personContacts.map { $0.asExternalModel() },
            affiliateIds: affiliateIds
        )
    }
}
