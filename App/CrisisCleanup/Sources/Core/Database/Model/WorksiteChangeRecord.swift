import Foundation
import GRDB

// TODO: Create database tables and related

struct WorksiteChangeRecord: Identifiable, Equatable {
    let id: Int64
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

    func asExternalModel(_ maxSyncLimit: Int = 3) -> SavedWorksiteChange {
        SavedWorksiteChange(
            id: id,
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

extension WorksiteChangeRecord: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns: String, ColumnExpression {
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
}

extension DerivableRequest<WorksiteChangeRecord> {
    func filterByWorksiteId(_ worksiteId: Int64) -> Self {
        filter(WorksiteChangeRecord.Columns.worksiteId == worksiteId)
    }
}
