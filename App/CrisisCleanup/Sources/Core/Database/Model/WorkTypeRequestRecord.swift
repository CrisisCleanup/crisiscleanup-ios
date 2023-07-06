import Foundation
import GRDB

// TODO: Create database tables and related

struct WorkTypeRequestRecord : Identifiable, Equatable {
    let id: Int64
    let networkId: Int64
    /**
     * Local ID. Use [WorksiteDao.getWorksiteId] to find local ID from incident and network ID.
     */
    let worksiteId: Int64
    let workType: String
    let reason: String
    let byOrg: Int64
    let toOrg: Int64
    let createdAt: Date
    let approvedAt: Date?
    let rejectedAt: Date?
    let approvedRejectedReason: String
}

extension WorkTypeRequestRecord: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns: String, ColumnExpression {
        case id,
             networkId,
             worksiteId,
             workType,
             reason,
             byOrg,
             toOrg,
             createdAt,
             approvedAt,
             rejectedAt,
             approvedRejectedReason
    }

    static func deleteUnsynced(_ db: Database, _ worksiteId: Int64) throws {
        try WorkTypeRequestRecord
            .all()
            .filter(
                WorkTypeRequestRecord.Columns.worksiteId == worksiteId &&
                WorkTypeRequestRecord.Columns.networkId <= 0
            )
            .deleteAll(db)
    }
}
