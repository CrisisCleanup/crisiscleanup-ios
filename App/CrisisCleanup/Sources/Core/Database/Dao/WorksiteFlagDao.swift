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
        try reader.read { db in try db.getWorksiteFlagNetworkedIdMap(worksiteId) }
    }
}

extension Database {
    func getUnsyncedFlagCount(_ worksiteId: Int64) throws -> Int {
        try WorksiteFlagRecord
            .all()
            .filterByUnsynced(worksiteId)
            .fetchCount(self)
    }

    func getWorksiteFlagNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try WorksiteFlagRecord
            .all()
            .selectIdNetworkIdColumns()
            .filter(
                WorksiteFlagRecord.Columns.worksiteId == worksiteId &&
                WorksiteFlagRecord.Columns.networkId > -1
            )
            .asRequest(of: PopulatedIdNetworkId.self)
            .fetchAll(self)
    }
}
