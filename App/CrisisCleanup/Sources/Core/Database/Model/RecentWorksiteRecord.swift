import Foundation
import GRDB

struct RecentWorksiteRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRecord.self)

    let id: Int64
    let incidentId: Int64
    let viewedAt: Date
}

extension RecentWorksiteRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "recentWorksite"

    // internal for testing. Should be fileprivate.
    internal enum Columns: String, ColumnExpression {
        case id,
             incidentId,
             viewedAt
    }

    static func updateIncident(
        _ db: Database,
        id: Int64,
        incidentId: Int64
    ) throws {
        try db.execute(
            sql:
                """
                UPDATE recentWorksite
                SET incidentId=:incidentId
                WHERE id=:id
                """,
            arguments: [
                "id": id,
                "incidentId": incidentId
            ]
        )
    }
}

extension DerivableRequest<RecentWorksiteRecord> {
    func byIncidentid(_ incidentId: Int64) -> Self {
        filter(RecentWorksiteRecord.Columns.incidentId == incidentId)
    }

    func orderedByViewedAtDesc() -> Self {
        order(RecentWorksiteRecord.Columns.viewedAt.desc)
    }
}
