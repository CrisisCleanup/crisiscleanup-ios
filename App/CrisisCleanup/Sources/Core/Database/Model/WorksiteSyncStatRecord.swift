import Foundation
import GRDB

struct WorksiteSyncStatRecord : Identifiable, Equatable {
    let id: Int64
    let syncStart: Date
    let targetCount: Int
    let pagedCount: Int
    let successfulSync: Date?
    let attemptedSync: Date?
    let attemptedCounter: Int
    let appBuildVersionCode: Int64

    func asExternalModel() -> IncidentDataSyncStats {
        IncidentDataSyncStats(
            incidentId: id,
            syncStart: syncStart,
            dataCount: targetCount,
            syncAttempt: SyncAttempt(
                successfulSeconds: successfulSync?.timeIntervalSince1970 ?? 0.0,
                attemptedSeconds: attemptedSync?.timeIntervalSince1970 ?? 0.0,
                attemptedCounter: attemptedCounter
            ),
            appBuildVersionCode: appBuildVersionCode
        )
    }
}

extension WorksiteSyncStatRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "worksiteSyncStat"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             syncStart,
             targetCount,
             pagedCount,
             successfulSync,
             attemptedSync,
             attemptedCounter,
             appBuildVersionCode
    }

    // TODO: Write tests espcially on the where clause

    static func updateIgnorePagedCount(
        _ db: Database,
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int
    ) throws {
        try db.execute(
            sql: """
                UPDATE OR IGNORE worksiteSyncStat
                SET pagedCount=:pagedCount
                WHERE id=:incidentId AND syncStart=:syncStart
                """,
            arguments: [
                Columns.pagedCount.rawValue: pagedCount,
                Columns.id.rawValue: incidentId,
                Columns.syncStart.rawValue: syncStart
            ]
        )
    }

    static func updateIgnoreSuccessful(
        _ db: Database,
        _ incidentId: Int64,
        _ syncStart: Date,
        _ pagedCount: Int,
        _ successfulSync: Date?,
        _ attemptedSync: Date?,
        _ attemptedCounter: Int,
        _ appBuildVersionCode: Int64
    ) throws {
        try db.execute(
            sql: """
            UPDATE OR IGNORE worksiteSyncStat
            SET
            pagedCount         =:pagedCount,
            successfulSync     =:successfulSync,
            attemptedSync      =:attemptedSync,
            attemptedCounter   =:attemptedCounter,
            appBuildVersionCode=:appBuildVersionCode
            WHERE id=:id AND syncStart=:syncStart
            """,
            arguments: [
                Columns.pagedCount.rawValue: pagedCount,
                Columns.successfulSync.rawValue: successfulSync,
                Columns.attemptedSync.rawValue: attemptedSync,
                Columns.attemptedCounter.rawValue: attemptedCounter,
                Columns.appBuildVersionCode.rawValue: appBuildVersionCode,
                Columns.id.rawValue: incidentId,
                Columns.syncStart.rawValue: syncStart
            ]
        )
    }
}

extension DerivableRequest<WorksiteSyncStatRecord> {
    func byId(_ incidentId: Int64) -> Self {
        filter(WorksiteSyncStatRecord.Columns.id == incidentId)
    }
}

extension IncidentDataSyncStats {
    func asWorksiteSyncStatsRecord() -> WorksiteSyncStatRecord {
        WorksiteSyncStatRecord(
            id: incidentId,
            syncStart: syncStart,
            targetCount: dataCount,
            pagedCount: pagedCount,
            successfulSync: syncAttempt.successfulSeconds <= 0 ? nil
            : Date(timeIntervalSince1970: syncAttempt.successfulSeconds),
            attemptedSync: syncAttempt.attemptedSeconds <= 0 ? nil
            : Date(timeIntervalSince1970: syncAttempt.attemptedSeconds),
            attemptedCounter: syncAttempt.attemptedCounter,
            appBuildVersionCode: appBuildVersionCode
        )
    }
}
