import Combine
import GRDB

public class WorkTypeTransferRequestDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func syncUpsert(_ records: [WorkTypeRequestRecord]) async throws {
        try await database.syncUpsertWorkTypeRequests(records)
    }
}

extension Database {
    func deleteUnsyncedWorkTypeTransferRequests(_ worksiteId: Int64) throws {
        // TODO: Uncomment when transfers are supported
        //try WorkTypeRequestRecord.deleteUnsynced(self, worksiteId)
    }
}

extension AppDatabase {
    fileprivate func syncUpsertWorkTypeRequests(_ records: [WorkTypeRequestRecord]) async throws {
        if let firstRecord = records.firstOrNil {
            let worksiteId = firstRecord.worksiteId
            try await dbWriter.write { db in
                try WorkTypeRequestRecord.syncDeleteUnspecified(
                    db,
                    worksiteId,
                    Set(records.map { $0.workType })
                )
                for record in records {
                    var record = record
                    try record.upsert(db)
                }
            }
        }
    }
}
