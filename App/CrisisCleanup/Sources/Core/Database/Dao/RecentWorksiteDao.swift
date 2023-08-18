import Combine
import Foundation
import GRDB

public class RecentWorksiteDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func streamRecentWorksites(
        _ incidentId: Int64,
        _ limit: Int = 29,
        _ offset: Int = 0
    ) -> AnyPublisher<[WorksiteSummary], Error> {
        ValueObservation
            .tracking { db in try self.fetchRecents(db, incidentId, limit, offset) }
            .map { $0.map { p in p.worksite.asSummary() } }
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    private func fetchRecents(
        _ db: Database,
        _ incidentId: Int64,
        _ limit: Int = 0,
        _ offset: Int = 0
    ) throws -> [PopulatedRecentWorksite] {
        try RecentWorksiteRecord
            .all()
            .byIncidentid(incidentId)
            .orderedByViewedAtDesc()
            .limit(limit, offset: offset)
            .including(required: RecentWorksiteRecord.worksite)
            .asRequest(of: PopulatedRecentWorksite.self)
            .fetchAll(db)
    }

    func upsert(_ recentWorksite: RecentWorksiteRecord) async throws {
        try await database.upsertRecentWorksite(recentWorksite)
    }
}

extension AppDatabase {
    fileprivate func upsertRecentWorksite(_ recentWorksite: RecentWorksiteRecord) async throws {
        try await dbWriter.write { db in
            try recentWorksite.upsert(db)
        }
    }
}

struct PopulatedRecentWorksite: Decodable, FetchableRecord {
    let recentWorksite: RecentWorksiteRecord
    let worksite: WorksiteRecord
}

extension WorksiteRecord {
    func asSummary() -> WorksiteSummary {
        WorksiteSummary(
            id: id!,
            networkId: networkId,
            name: name,
            address: address,
            city: city,
            state: state,
            zipCode: postalCode,
            county: county,
            caseNumber: caseNumber,
            workType: WorkType(
                id: 0,
                statusLiteral: keyWorkTypeStatus,
                workTypeLiteral: keyWorkTypeType
            )
        )
    }
}
