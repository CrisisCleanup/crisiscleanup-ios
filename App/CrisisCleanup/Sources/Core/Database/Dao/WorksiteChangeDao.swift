import GRDB

class WorksiteChangeDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getOrdered(_ worksiteId: Int64) -> [WorksiteChangeRecord] {
        // TODO: Do
        return []
    }

    func updateSyncIds(worksiteId: Int64, organizationId: Int64, ids: WorksiteSyncResult.ChangeIds) {
        // TODO: Do
    }

    func updateSyncChanges(
        worksiteId: Int64,
        changeResults: [WorksiteSyncResult.ChangeResult],
        maxSyncAttempts: Int = 3
    ) {
        // TODO: Do
    }
}

extension Database {
    func getWorksiteChangeCount(_ worksiteId: Int64) throws -> Int {
        0
        // TODO: Uncomment when changes are saved
//        try WorksiteChangeRecord
//            .all()
//            .filterByWorksiteId(worksiteId)
//            .fetchCount(self)
    }
}
