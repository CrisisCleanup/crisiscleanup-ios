import Foundation
import GRDB

// sourcery: copyBuilder
struct WorkTypeRequestRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

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

    static func create(
        worksite: Worksite,
        workType: String,
        reason: String,
        byOrg: Int64,
        toOrg: Int64,
        createdAt: Date
    ) -> WorkTypeRequestRecord {
        WorkTypeRequestRecord(
            networkId: -1,
            worksiteId: worksite.id,
            workType: workType,
            reason: reason,
            byOrg: byOrg,
            toOrg: toOrg,
            createdAt: createdAt,
            approvedAt: nil,
            rejectedAt: nil,
            approvedRejectedReason: ""
        )
    }

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

private typealias RequestColumns = WorkTypeRequestRecord.Columns

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
            .filter(RequestColumns.worksiteId == worksiteId &&
                    RequestColumns.networkId>0 &&
                    !keepWorkTypes.contains(RequestColumns.workType))
            .deleteAll(db)
    }

    static func deleteUnsynced(_ db: Database, _ worksiteId: Int64) throws {
        try WorkTypeRequestRecord
            .filter(
                RequestColumns.worksiteId == worksiteId &&
                RequestColumns.networkId <= 0
            )
            .deleteAll(db)
    }

    static func updateNetworkId(
        _ db: Database,
        _ worksiteId: Int64,
        _ workType: String,
        _ orgId: Int64,
        _ networkId: Int64
    ) throws {
        try db.execute(
            sql:
                """
                UPDATE OR IGNORE worksiteWorkTypeRequest
                SET networkId =:networkId
                WHERE worksiteId=:worksiteId AND workType=:workType AND byOrg=:orgId
                """,
            arguments: [
                "worksiteId": worksiteId,
                "workType": workType,
                "orgId": orgId,
                "networkId": networkId
            ]
        )
    }
}

extension DerivableRequest<WorkTypeRequestRecord> {
    func selectIdNetworkIdColumns() -> Self {
        select(RequestColumns.id, RequestColumns.networkId)
    }
}
