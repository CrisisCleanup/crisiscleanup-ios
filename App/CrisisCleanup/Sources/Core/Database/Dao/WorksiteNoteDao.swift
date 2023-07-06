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
        try reader.read { db in
            try WorksiteNoteRecord
                .all()
                .selectIdNetworkIdColumns()
                .asRequest(of: PopulatedIdNetworkId.self)
                .fetchAll(db)
        }
    }
}

extension Database {
    func getUnsyncedNoteCount(_ worksiteId: Int64) throws -> Int {
        try WorksiteNoteRecord
            .all()
            .filterByUnsynced(worksiteId)
            .fetchCount(self)
    }
}
