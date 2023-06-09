import Combine
import Foundation
import GRDB

public class WorksiteSyncStatDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func updateStatsPaged(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int
    ) async throws {
        try await database.updateStatsPaged(incidentId, syncStart, pagedCount)
    }

    func updateStatsSuccessful(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int,
        _ successfulSync: Date?,
        _ attemptedSync: Date?,
        _ attemptedCounter: Int,
        _ appBuildVersionCode: Int64
    ) async throws {
        try await database.updateStatsSuccessful(
            incidentId,
            syncStart,
            pagedCount,
            successfulSync,
            attemptedSync,
            attemptedCounter,
            appBuildVersionCode
        )
    }

    func upsertStats(_ stats: WorksiteSyncStatRecord) async throws {
        try await database.upsertWorksiteSyncStats(stats)
    }

    func getSyncStats(_ incidentId: Int64) throws -> IncidentDataSyncStats? {
        try reader.read { db in
            try WorksiteSyncStatRecord.all()
                .byId(incidentId)
                .fetchOne(db)
        }?.asExternalModel()
    }
}

extension AppDatabase {
    fileprivate func updateStatsPaged(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int
    ) async throws {
        try await dbWriter.write { db in
            try WorksiteSyncStatRecord.updateIgnorePagedCount(
                db,
                incidentId,
                syncStart,
                pagedCount
            )
        }
    }

    fileprivate func updateStatsSuccessful(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int,
        _ successfulSync: Date?,
        _ attemptedSync: Date?,
        _ attemptedCounter: Int,
        _ appBuildVersionCode: Int64
    ) async throws {
        try await dbWriter.write { db in
            try WorksiteSyncStatRecord.updateIgnoreSuccessful(
                db,
                incidentId,
                syncStart,
                pagedCount,
                successfulSync,
                attemptedSync,
                attemptedCounter,
                appBuildVersionCode
            )
        }
    }

    fileprivate func upsertWorksiteSyncStats(
        _ stats: WorksiteSyncStatRecord
    ) async throws {
        try await dbWriter.write { db in try stats.upsert(db) }
    }
}
