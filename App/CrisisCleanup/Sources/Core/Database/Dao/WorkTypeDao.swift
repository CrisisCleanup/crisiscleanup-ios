import Combine
import GRDB

public class WorkTypeDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try reader.read { db in try db.getWorkTypeNetworkedIdMap(worksiteId) }
    }
}

extension Database {
    func getUnsyncedWorkTypeCount(_ worksiteId: Int64) throws -> Int {
        try WorkTypeRecord
            .all()
            .filterByUnsynced(worksiteId)
            .fetchCount(self)
    }

    func getWorkTypeNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try WorkTypeRecord
            .all()
            .selectIdNetworkIdColumns()
            .filter(WorksiteFlagRecord.Columns.networkId > -1)
            .asRequest(of: PopulatedIdNetworkId.self)
            .fetchAll(self)
    }
}
