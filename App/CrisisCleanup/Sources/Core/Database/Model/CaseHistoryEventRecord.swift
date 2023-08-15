import Foundation
import GRDB

struct CaseHistoryEventRecord: Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)
    static let attr = hasOne(CaseHistoryEventAttrRecord.self)

    let id: Int64
    let worksiteId: Int64
    let createdAt: Date
    let createdBy: Int64
    let eventKey: String
    let pastTenseT: String
    let actorLocationName: String
    let recipientLocationName: String?
}

extension CaseHistoryEventRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "caseHistoryEvent"

    internal enum Columns: String, ColumnExpression {
        case id,
             worksiteId,
             createdAt,
             createdBy,
             eventKey,
             pastTenseT,
             actorLocationName,
             recipientLocationName
    }

    static func deleteUnspecified(
        _ db: Database,
        _ worksiteId: Int64,
        _ ids: Set<Int64>
    ) throws {
        try CaseHistoryEventRecord
            .filter(Columns.worksiteId == worksiteId && !ids.contains(Columns.id))
            .deleteAll(db)
    }
}

extension DerivableRequest<CaseHistoryEventRecord> {
    func byWorksiteId(_ worksiteId: Int64) -> Self {
        filter(CaseHistoryEventRecord.Columns.worksiteId == worksiteId)
    }
}

struct CaseHistoryEventAttrRecord: Identifiable, Equatable {
    static let worksite = belongsTo(CaseHistoryEventRecord.self)

    let id: Int64
    let incidentName: String
    let patientCaseNumber: String?
    let patientId: Int64
    let patientLabelT: String?
    let patientLocationName: String?
    let patientNameT: String?
    let patientReasonT: String?
    let patientStatusNameT: String?
    let recipientCaseNumber: String?
    let recipientId: Int64?
    let recipientName: String?
    let recipientNameT: String?
}

extension CaseHistoryEventAttrRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "caseHistoryEventAttr"

    internal enum Columns: String, ColumnExpression {
        case id,
             incidentName,
             patientCaseNumber,
             patientId,
             patientLabelT,
             patientLocationName,
             patientNameT,
             patientReasonT,
             patientStatusNameT,
             recipientCaseNumber,
             recipientId,
             recipientName,
             recipientNameT
    }
}
