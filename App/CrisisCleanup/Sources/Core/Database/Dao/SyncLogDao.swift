import Combine
import Foundation
import GRDB

public class SyncLogDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func streamLogCount() -> any Publisher<Int, Never> {
        ValueObservation
            .tracking(fetchLogCount(_:))
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
    }

    private func fetchLogCount(_ db: Database) throws -> Int {
        try SyncLogRecord
            .fetchCount(db)
    }

    func getSyncLogs(_ limit: Int = 20, _ offset: Int = 0) -> [SyncLogRecord] {
        try! reader.read { db in
            try SyncLogRecord
                .all()
                .orderByLogTimeDesc()
                .limit(limit, offset: offset)
                .fetchAll(db)
        }
    }

    func insertSyncLogs(_ logs: [SyncLogRecord]) async throws {
        try await database.insertSyncLogs(logs)
    }

    func trimOldSyncLogs(_ minLogTime: Date = Date.now.addingTimeInterval(-14.days)) async {
        try! await database.trimOldSyncLogs(minLogTime)
    }
}

extension AppDatabase {
    fileprivate func insertSyncLogs(_ logs: [SyncLogRecord]) async throws {
        try await dbWriter.write { db in
            for log in logs {
                _ = try log.insertAndFetch(db, onConflict: .ignore)
            }
        }
    }

    fileprivate func trimOldSyncLogs(_ minLogTime: Date) async throws {
        try await dbWriter.write { db in
            _ = try SyncLogRecord.deleteOlderThan(db, minLogTime)
        }
    }
}
