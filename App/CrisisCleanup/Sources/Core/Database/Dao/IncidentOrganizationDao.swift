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
            .shared(in: reader)
            .publisher()
            .map {
                $0.map { record in OrganizationIdName(id: record.id, name: record.name) }
            }
            .eraseToAnyPublisher()
    }

    private func fetchOrganizationsIdName(_ db: Database) throws -> [IncidentOrganizationRecord] {
        try IncidentOrganizationRecord.fetchAll(db)
    }

    func streamOrganizations() -> AnyPublisher<[PopulatedIncidentOrganization], Error> {
        ValueObservation
            .tracking(fetchOrganizations(_:))
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    private func fetchOrganizations(_ db: Database) throws -> [PopulatedIncidentOrganization] {
        try IncidentOrganizationRecord
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

    func streamLocationIds(_ orgId: Int64) -> AnyPublisher<PopulatedOrganizationLocationIds?, Never> {
        ValueObservation
            .tracking { db in
                try IncidentOrganizationRecord
                    .select(IncidentOrganizationRecord.locationColumns)
                    .byId(orgId)
                    .asRequest(of: PopulatedOrganizationLocationIds.self)
                    .fetchOne(db)
            }
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
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
                .all()
                .inIds(organizationIds)
                .including(all: IncidentOrganizationRecord.primaryContacts)
                .including(all: IncidentOrganizationRecord.organizationAffiliates)
                .asRequest(of: PopulatedIncidentOrganization.self)
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

    func getMatchingOrganizations(_ q: String) -> [OrganizationIdName] {
        try! reader.read { db in matchOrganizations(db, q) }
            .map {
                OrganizationIdName(id: $0.id, name: $0.name)
            }
    }

    private func matchOrganizations(_ db: Database, _ q: String) -> [IncidentOrganizationRecord] {
        let sql = """
                SELECT o.id, o.name
                FROM incidentOrganization o
                JOIN incidentOrganization_ft fts
                    ON fts.rowid = o.rowid
                WHERE incidentOrganization_ft MATCH ?
                """
        let pattern = FTS3Pattern(matchingAllPrefixesIn: q)
        return try! IncidentOrganizationRecord.fetchAll(
            db,
            sql: sql,
            arguments: [pattern]
        )
    }

    func streamMatchingOrganizations(_ q: String) -> AnyPublisher<[OrganizationIdName], Error> {
        ValueObservation
            .tracking { db in
                self.matchOrganizations(db, q)
                    .map {
                        OrganizationIdName(id: $0.id, name: $0.name)
                    }
            }
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    func findOrganization(_ id: Int64) -> Int64? {
        try! reader.read{ db in
            try IncidentOrganizationRecord
                .select(IncidentOrganizationRecord.idColumn)
                .byId(id)
                .asRequest(of: Int64.self)
                .fetchOne(db)
        }
    }

    func saveMissing(
        _ organizations: [IncidentOrganizationRecord],
        _ affiliateIds: [[Int64]]
    ) throws {
        var newOrganizations = [IncidentOrganizationRecord]()
        var newAffiliates = [OrganizationAffiliateRecord]()
        for i in organizations.indices {
            let organization = organizations[i]
            if findOrganization(organization.id) == nil {
                newOrganizations.append(organization)
                let affiliates = affiliateIds[i].map {
                    OrganizationAffiliateRecord(id: organization.id, affiliateId: $0)
                }
                newAffiliates.append(contentsOf: affiliates)
            }
        }
        try database.saveOrganizations(newOrganizations, newAffiliates)
    }

    func rebuildOrganizationFts() throws {
        try database.rebuildFtsTable("incidentOrganization_ft")
    }
}

extension AppDatabase {
    fileprivate func saveOrganizations(
        _ organizations: [IncidentOrganizationRecord],
        _ primaryContacts: [PersonContactRecord]
    ) async throws {
        try await dbWriter.write { db in
            // TODO: Upsert here clears primary and secondary location values when it shouldn't
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
        try await dbWriter.write { db in
            try OrganizationToPrimaryContactRecord
                .deleteInIds(db, organizationIds)
            for record in organizationContactCrossRefs {
                try record.insert(db, onConflict: .ignore)
            }

            try OrganizationAffiliateRecord
                .deleteInIds(db, organizationIds)
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

    fileprivate func saveOrganizations(
        _ organizations: [IncidentOrganizationRecord],
        _ affiliates: [OrganizationAffiliateRecord]
    ) throws {
        try dbWriter.write { db in
            for record in organizations {
                try record.upsert(db)
            }
            for record in affiliates {
                try record.insert(db, onConflict: .ignore)
            }
        }
    }
}

struct PopulatedIncidentOrganization: Equatable, Decodable, FetchableRecord {
    let incidentOrganization: IncidentOrganizationRecord
    // Changing the name will affect deserialization. Modify accordingly.
    let personContacts: [PersonContactRecord]
    let organizationAffiliates: [OrganizationAffiliateRecord]

    func asExternalModel() -> IncidentOrganization {
        var affiliateIds = Set(organizationAffiliates.map { $0.affiliateId })
        affiliateIds.insert(incidentOrganization.id)
        return IncidentOrganization(
            id: incidentOrganization.id,
            name: incidentOrganization.name,
            primaryContacts: personContacts.map { $0.asExternalModel() },
            affiliateIds: affiliateIds
        )
    }
}
