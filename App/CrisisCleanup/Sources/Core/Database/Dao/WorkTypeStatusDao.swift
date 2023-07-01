import Combine
import GRDB

public class WorkTypeStatusDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func upsert(_ statuses: [WorkTypeStatusRecord]) async throws {
        try await database.upsertWorkTypeStatuses(statuses)
    }

    func getCount() throws -> Int {
        try reader.read { db in
            try WorkTypeStatusRecord.fetchCount(db)
        }
    }

    func getStatuses() throws -> [PopulatedWorkTypeStatus] {
        try reader.read { db in
            try WorkTypeStatusRecord
                .all()
                .orderedByListOrderDesc()
                .fetchAll(db)
        }.map { record in
            PopulatedWorkTypeStatus(
                status: record.id,
                name: record.name,
                primaryState: record.primaryState
            )
        }
    }
}

extension AppDatabase {
    fileprivate func upsertWorkTypeStatuses(_ statuses: [WorkTypeStatusRecord]) async throws {
        try await dbWriter.write { db in
            for status in statuses {
                try status.upsert(db)
            }
        }
    }
}

struct PopulatedWorkTypeStatus {
    let status: String
    let name: String
    let primaryState: String
}
