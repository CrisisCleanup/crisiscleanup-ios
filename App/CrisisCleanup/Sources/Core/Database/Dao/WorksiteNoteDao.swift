import Combine
import GRDB

public class WorksiteNoteDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try reader.read { db in try db.getWorksiteNoteNetworkedIdMap(worksiteId) }
    }
}

extension Database {
    func getUnsyncedNoteCount(_ worksiteId: Int64) throws -> Int {
        try WorksiteNoteRecord
            .all()
            .filterByUnsynced(worksiteId)
            .fetchCount(self)
    }

    func getWorksiteNoteNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try WorksiteNoteRecord
            .all()
            .selectIdNetworkIdColumns()
            .filter(WorksiteFlagRecord.Columns.networkId > -1)
            .asRequest(of: PopulatedIdNetworkId.self)
            .fetchAll(self)
    }
}
