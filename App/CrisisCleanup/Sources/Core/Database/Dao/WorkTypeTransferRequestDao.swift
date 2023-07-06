import Combine
import GRDB

public class WorkTypeTransferRequestDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }
}

extension Database {
    func deleteUnsyncedWorkTypeTransferRequests(_ worksiteId: Int64) throws {
        // TODO: Uncomment when transfers are supported
        //try WorkTypeRequestRecord.deleteUnsynced(self, worksiteId)
    }
}
