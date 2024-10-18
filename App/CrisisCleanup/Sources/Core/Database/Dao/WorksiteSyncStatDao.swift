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

    func getFullSyncStats(_ incidentId: Int64) throws -> PopulatedSyncStats? {
        try reader.read { db in try fetchFullSyncStats(db, incidentId) }
    }

    // internal for testing. Should be private.
    internal func fetchFullSyncStats(_ db: Database, _ incidentId: Int64) throws -> PopulatedSyncStats? {
        try WorksiteSyncStatRecord
            .filter(id: incidentId)
            .including(optional: WorksiteSyncStatRecord.secondarySyncStats)
            .asRequest(of: PopulatedSyncStats.self)
            .fetchOne(db)
    }

    func upsertSecondaryStats(_ stats: IncidentWorksitesSecondarySyncStatsRecord) async throws {
        try await database.upsertWorksiteSecondarySyncStats(stats)
    }

    func updateSecondaryStatsPaged(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int
    ) async throws {
        try await database.updateSecondaryStatsPaged(incidentId, syncStart, pagedCount)
    }

    func updateSecondaryStatsSuccessful(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int,
        _ successfulSync: Date?,
        _ attemptedSync: Date?,
        _ attemptedCounter: Int,
        _ appBuildVersionCode: Int64
    ) async throws {
        try await database.updateSecondaryStatsSuccessful(
            incidentId,
            syncStart,
            pagedCount,
            successfulSync,
            attemptedSync,
            attemptedCounter,
            appBuildVersionCode
        )
    }

    func getWorksiteSyncStatCount() -> Int {
        try! reader.read(WorksiteSyncStatRecord.fetchCount(_:))
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

    fileprivate func upsertWorksiteSecondarySyncStats(
        _ stats: IncidentWorksitesSecondarySyncStatsRecord
    ) async throws {
        try await dbWriter.write { db in try stats.upsert(db) }
    }

    fileprivate func updateSecondaryStatsPaged(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int
    ) async throws {
        try await dbWriter.write { db in
            try IncidentWorksitesSecondarySyncStatsRecord.updateIgnorePagedCount(
                db,
                incidentId,
                syncStart,
                pagedCount
            )
        }
    }

    fileprivate func updateSecondaryStatsSuccessful(
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int,
        _ successfulSync: Date?,
        _ attemptedSync: Date?,
        _ attemptedCounter: Int,
        _ appBuildVersionCode: Int64
    ) async throws {
        try await dbWriter.write { db in
            try IncidentWorksitesSecondarySyncStatsRecord.updateIgnoreSuccessful(
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
}
