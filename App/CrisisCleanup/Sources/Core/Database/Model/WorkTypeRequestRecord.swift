import Foundation
import GRDB

// sourcery: copyBuilder
struct WorkTypeRequestRecord : Identifiable, Equatable {
    var id: Int64?
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

    func asExternalModel() -> WorkTypeRequest {
        WorkTypeRequest(
            workType: workType,
            byOrg: byOrg,
            createdAt: createdAt,
            approvedAt: approvedAt,
            rejectedAt: rejectedAt,
            approvedRejectedReason: approvedRejectedReason
        )
    }
}

extension WorkTypeRequestRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksiteWorkTypeRequest"
    internal enum Columns: String, ColumnExpression {
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

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func syncDeleteUnspecified(
        _ db: Database,
        _ worksiteId: Int64,
        _ keepWorkTypes: Set<String>
    ) throws {
        try WorkTypeRequestRecord
            .filter(WorkTypeRequestRecord.Columns.worksiteId == worksiteId &&
                    WorkTypeRequestRecord.Columns.networkId>0 &&
                    !keepWorkTypes.contains(WorkTypeRequestRecord.Columns.workType))
            .deleteAll(db)
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
