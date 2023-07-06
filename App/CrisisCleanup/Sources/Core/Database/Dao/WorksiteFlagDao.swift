import Combine
import GRDB

public class WorksiteFlagDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try reader.read { db in
            try WorksiteFlagRecord
                .all()
                .selectIdNetworkIdColumns()
                .asRequest(of: PopulatedIdNetworkId.self)
                .fetchAll(db)
        }
    }
}

extension Database {
    func getUnsyncedFlagCount(_ worksiteId: Int64) throws -> Int {
        try WorksiteFlagRecord
            .all()
            .filterByUnsynced(worksiteId)
            .fetchCount(self)
    }
}
