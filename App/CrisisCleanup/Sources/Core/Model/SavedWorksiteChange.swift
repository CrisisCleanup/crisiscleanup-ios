import Foundation

public struct SavedWorksiteChange: Equatable {
    let id: Int64
    let syncUuid: String
    let createdAt: Date
    let organizationId: Int64
    let worksiteId: Int64
    let dataVersion: Int
    let serializedData: String
    private let saveAttempt: Int
    private let archiveActionLiteral: String
    private let stopSyncing: Bool

    // sourcery:begin: skipCopy
    let isSynced: Bool
    let isPartiallySynced: Bool

    let isArchived: Bool
    // sourcery:end

    init(
        id: Int64,
        syncUuid: String,
        createdAt: Date,
        organizationId: Int64,
        worksiteId: Int64,
        dataVersion: Int,
        serializedData: String,
        saveAttempt: Int,
        archiveActionLiteral: String,
        stopSyncing: Bool
    ) {
        self.id = id
        self.syncUuid = syncUuid
        self.createdAt = createdAt
        self.organizationId = organizationId
        self.worksiteId = worksiteId
        self.dataVersion = dataVersion
        self.serializedData = serializedData
        self.saveAttempt = saveAttempt
        self.archiveActionLiteral = archiveActionLiteral
        self.stopSyncing = stopSyncing

        let archiveAction = {
            switch archiveActionLiteral {
            case WorksiteChangeArchiveAction.synced.literal: return WorksiteChangeArchiveAction.synced
            case WorksiteChangeArchiveAction.partiallySynced.literal: return WorksiteChangeArchiveAction.partiallySynced
            default: return WorksiteChangeArchiveAction.pending
            }
        }()

        self.isSynced = archiveAction == WorksiteChangeArchiveAction.synced
        self.isPartiallySynced = archiveAction == WorksiteChangeArchiveAction.partiallySynced
        self.isArchived = stopSyncing || isSynced
    }
}

enum WorksiteChangeArchiveAction: String, Identifiable, CaseIterable {
    /// Pending sync
    case pending,

         /// Synced successfully
         synced,

         /// Worksite was synced but not all additional data was synced
         partiallySynced

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .pending: return ""
        case .synced: return "synced"
        case .partiallySynced: return "partially_synced"
        }
    }
}
