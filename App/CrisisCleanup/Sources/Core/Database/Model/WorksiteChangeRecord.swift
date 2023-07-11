import Foundation
import GRDB

struct WorksiteChangeRecord: Identifiable, Equatable {
    var id: Int64?
    let appVersion: Int64
    let organizationId: Int64
    let worksiteId: Int64
    // Only applies to worksite core data. Attaching data can check on keys or content.
    let syncUuid: String
    let changeModelVersion: Int
    let changeData: String
    let createdAt: Date
    let saveAttempt: Int
    /**
     * - SeeAlso: [WorksiteChangeArchiveAction]
     */
    let archiveAction: String
    let saveAttemptAt: Date

    init(
        id: Int64? = nil,
        appVersion: Int64,
        organizationId: Int64,
        worksiteId: Int64,
        syncUuid: String,
        changeModelVersion: Int,
        changeData: String,
        createdAt: Date = Date.now,
        saveAttempt: Int = 0,
        archiveAction: String = "",
        saveAttemptAt: Date = Date(timeIntervalSince1970: 0)
    ) {
            self.id = id
            self.appVersion = appVersion
            self.organizationId = organizationId
            self.worksiteId = worksiteId
            self.syncUuid = syncUuid
            self.changeModelVersion = changeModelVersion
            self.changeData = changeData
            self.createdAt = createdAt
            self.saveAttempt = saveAttempt
            self.archiveAction = archiveAction
            self.saveAttemptAt = saveAttemptAt
        }

    func asExternalModel(_ maxSyncLimit: Int = 3) -> SavedWorksiteChange {
        SavedWorksiteChange(
            id: id!,
            syncUuid: syncUuid,
            createdAt: createdAt,
            organizationId: organizationId,
            worksiteId: worksiteId,
            dataVersion: changeModelVersion,
            serializedData: changeData,
            saveAttempt: saveAttempt,
            archiveActionLiteral: archiveAction,
            stopSyncing: saveAttempt > maxSyncLimit
        )
    }
}

extension WorksiteChangeRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksiteChange"

    internal enum Columns: String, ColumnExpression {
        case id,
             appVersion,
             organizationId,
             worksiteId,
             syncUuid,
             changeModelVersion,
             changeData,
             createdAt,
             saveAttempt
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension DerivableRequest<WorksiteChangeRecord> {
    func filterByWorksiteId(_ worksiteId: Int64) -> Self {
        filter(WorksiteChangeRecord.Columns.worksiteId == worksiteId)
    }
}
