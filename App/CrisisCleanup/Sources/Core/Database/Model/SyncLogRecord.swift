import Foundation
import GRDB

struct SyncLogRecord: Identifiable, Equatable {
    var id: Int64?
    let logTime: Date
    let logType: String
    let message: String
    let details: String

    func asExternalModel() -> SyncLog {
        SyncLog(
            id: id,
            logTime: logTime,
            logType: logType,
            message: message,
            details: details
        )
    }
}

extension SyncLogRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "syncLog"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             logTime,
             logType,
             message,
             details
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func deleteOlderThan(
        _ db: Database,
        _ date: Date
    ) throws {
        try SyncLogRecord
            .filter(SyncLogRecord.Columns.logTime < date)
            .deleteAll(db)
    }
}

extension DerivableRequest<SyncLogRecord> {
    func orderByLogTimeDesc() -> Self {
        order(SyncLogRecord.Columns.logTime.desc)
    }
}
