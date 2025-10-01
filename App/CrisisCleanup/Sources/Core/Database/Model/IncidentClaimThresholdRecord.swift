import Foundation
import GRDB

struct IncidentClaimThresholdRecord: Equatable {
    static let incident = belongsTo(IncidentRecord.self)

    let userId: Int64
    let incidentId: Int64
    let userClaimCount: Int
    let userCloseRatio: Float

    init(
        userId: Int64,
        incidentId: Int64,
        userClaimCount: Int,
        userCloseRatio: Float,
    ) {
        self.userId = userId
        self.incidentId = incidentId
        self.userClaimCount = userClaimCount
        self.userCloseRatio = userCloseRatio
    }
}

extension IncidentClaimThresholdRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentClaimThreshold"

    fileprivate enum Columns: String, ColumnExpression {
        case userId,
             incidentId,
             userClaimCount,
             userCloseRatio
    }

    static func deleteUnspecified(
        _ db: Database,
        _ accountId: Int64,
        _ keepIncidentIds: Set<Int64>
    ) throws {
        try IncidentClaimThresholdRecord
            .filter(Columns.userId == accountId && !keepIncidentIds.contains(Columns.incidentId))
            .deleteAll(db)
    }

    static func filterBy(
        accountId: Int64,
        incidentId: Int64,
    ) -> SQLSpecificExpressible {
        Columns.userId == accountId &&
        Columns.incidentId == incidentId
    }
}
