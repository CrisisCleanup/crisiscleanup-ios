import Foundation
import GRDB

class WorksiteChangeDao {
    private let database: AppDatabase
    private let reader: DatabaseReader
    private let uuidGenerator: UuidGenerator
    private let changeSerializer: WorksiteChangeSerializer
    private let appVersionProvider: AppVersionProvider
    private let syncLogger: SyncLogger

    init(
        _ database: AppDatabase,
        uuidGenerator: UuidGenerator,
        changeSerializer: WorksiteChangeSerializer,
        appVersionProvider: AppVersionProvider,
        syncLogger: SyncLogger
    ) {
        self.database = database
        reader = database.reader
        self.uuidGenerator = uuidGenerator
        self.changeSerializer = changeSerializer
        self.appVersionProvider = appVersionProvider
        self.syncLogger = syncLogger
    }

    func getOrdered(_ worksiteId: Int64) -> [WorksiteChangeRecord] {
        // TODO: Do
        return []
    }

    func updateSyncIds(worksiteId: Int64, organizationId: Int64, ids: WorksiteSyncResult.ChangeIds) {
        // TODO: Do
    }

    func updateSyncChanges(
        worksiteId: Int64,
        changeResults: [WorksiteSyncResult.ChangeResult],
        maxSyncAttempts: Int = 3
    ) {
        // TODO: Do
    }

    func saveChange(
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        primaryWorkType: WorkType,
        organizationId: Int64,
        localModifiedAt: Date = Date.now
    ) async throws -> Int64 {
        if worksiteStart == worksiteChange {
            return worksiteStart.id
        }

        return try await database.saveWorksiteChange(
            syncLogger,
            uuidGenerator,
            appVersionProvider,
            changeSerializer,
            worksiteStart: worksiteStart,
            worksiteChange: worksiteChange,
            primaryWorkType: primaryWorkType,
            organizationId: organizationId,
            localModifiedAt: localModifiedAt
        )
    }
}

extension Database {
    func getWorksiteChangeCount(_ worksiteId: Int64) throws -> Int {
        try WorksiteChangeRecord
            .all()
            .filterByWorksiteId(worksiteId)
            .fetchCount(self)
    }

    fileprivate func saveWorksiteChange(
        _ changeSerializer: WorksiteChangeSerializer,
        _ uuidGenerator: UuidGenerator,
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        idMapping: IdNetworkIdMaps,
        appVersion: Int64,
        organizationId: Int64
    ) throws {
        let (changeVersion, serializedChange) = try changeSerializer.serialize(
            isDataChange: true,
            worksiteStart: worksiteStart,
            worksiteChange: worksiteChange,
            flagIdLookup: idMapping.flag,
            noteIdLookup: idMapping.note,
            workTypeIdLookup: idMapping.workType
        )
        var changeEntity = WorksiteChangeRecord(
            appVersion: appVersion,
            organizationId: organizationId,
            worksiteId: worksiteChange.id,
            syncUuid: uuidGenerator.uuid(),
            changeModelVersion: changeVersion,
            changeData: serializedChange
        )
        _ = try changeEntity.insert(self, onConflict: .rollback)
    }
}

extension AppDatabase {
    private func getLocalNetworkIdMap(
        _ db: Database,
        _ worksite: Worksite
    ) throws -> IdNetworkIdMaps {
        if (worksite.isNew || worksite.networkId < 0) {
            return IdNetworkIdMaps()
        }

        let flagIdMap = try db.getWorksiteFlagNetworkedIdMap(worksite.id).asLookup()
        let noteIdMap = try db.getWorksiteNoteNetworkedIdMap(worksite.id).asLookup()
        let workTypeIdMap = try db.getWorkTypeNetworkedIdMap(worksite.id).asLookup()
        return IdNetworkIdMaps(
            flag: flagIdMap,
            note: noteIdMap,
            workType: workTypeIdMap
        )
    }

    fileprivate func saveWorksiteChange(
        _ syncLogger: SyncLogger,
        _ uuidGenerator: UuidGenerator,
        _ appVersionProvider: AppVersionProvider,
        _ changeSerializer: WorksiteChangeSerializer,
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        primaryWorkType: WorkType,
        organizationId: Int64,
        localModifiedAt: Date
    ) async throws -> Int64 {
        return try await dbWriter.write { db in
            var worksiteId = worksiteChange.id

            var syncLogger = syncLogger
            let logPostfix = localModifiedAt.timeIntervalSince1970.rounded()
            syncLogger.type = worksiteChange.isNew
            ? "worksite-new-\(logPostfix)"
            : "worksite-update-\(worksiteId)-\(logPostfix)"

            do {
                defer {
                    syncLogger.flush()
                }

                let idMapping = try getLocalNetworkIdMap(db, worksiteChange)

                let changeRecords = worksiteChange.asRecords(
                    uuidGenerator,
                    primaryWorkType,
                    flagIdLookup: idMapping.flag,
                    noteIdLookup: idMapping.note,
                    workTypeIdLookup: idMapping.workType
                )

                var flags = changeRecords.flags
                var formData = changeRecords.formData
                var insertNotes = changeRecords.notes.filter { $0.id == nil }
                var workTypes = changeRecords.workTypes

                if worksiteChange.isNew {
                    var rootRecord = WorksiteRootRecord(
                        id: nil,
                        syncUuid: uuidGenerator.uuid(),
                        localModifiedAt: localModifiedAt,
                        syncedAt: Date(timeIntervalSince1970: 0),
                        localGlobalUuid: uuidGenerator.uuid(),
                        isLocalModified: true,
                        syncAttempt: 0,
                        networkId: -1,
                        incidentId: changeRecords.core.incidentId
                    )

                    try rootRecord.insert(db, onConflict: .rollback)
                    worksiteId = rootRecord.id!
                    var worksiteRecord = changeRecords.core.copy { $0.id = worksiteId }
                    try worksiteRecord.insert(db, onConflict: .rollback)

                    syncLogger.log("Saved new worksite: \(worksiteId)")

                    flags = flags.map { flag in
                        flag.copy { $0.worksiteId = worksiteId }
                    }
                    formData = formData.map { formData in
                        formData.copy { $0.worksiteId = worksiteId }
                    }
                    insertNotes = insertNotes.map { note in
                        note.copy { $0.worksiteId = worksiteId }
                    }
                    workTypes = workTypes.map { workType in
                        workType.copy { $0.worksiteId = worksiteId }
                    }
                } else {
                    let core = changeRecords.core
                    // TODO: Test coverage on incident ID change/update
                    try WorksiteRootRecord.localModifyUpdate(
                        db,
                        id: core.id!,
                        incidentId: core.incidentId,
                        syncUuid: uuidGenerator.uuid(),
                        localModifiedAt: localModifiedAt
                    )

                    try changeRecords.core.update(db, onConflict: .rollback)

                    try WorksiteFlagRecord.deleteUnspecified(
                        db,
                        worksiteId,
                        Set(flags.filter { $0.id != nil }.map { $0.id! })
                    )
                    try WorksiteFormDataRecord.deleteUnspecifiedKeys(
                        db,
                        worksiteId,
                        Set(formData.map { $0.fieldKey })
                    )
                    try WorkTypeRecord.deleteUnspecified(
                        db,
                        worksiteId,
                        Set(workTypes.map { $0.workType })
                    )
                }

                var worksiteUpdatedIds = worksiteChange.copy { $0.id = worksiteId }

                try with(flags.split { $0.id == nil }) { flagRecordSplit in
                    let (inserts, updates) = flagRecordSplit
                    var insertIds: [Int64] = []
                    for record in inserts {
                        var record = record
                        try record.insert(db, onConflict: .ignore)
                        insertIds.append(record.id!)
                    }
                    let unsyncedLookup = inserts.enumerated()
                        .map { (index, f) in
                            let id = insertIds[index]
                            return id > 0 ? (f.reasonT, id) : nil
                        }
                        .filter { $0 != nil}
                        .associate { ($0!.0, $0!.1) }
                    if unsyncedLookup.isNotEmpty {
                        if let updatedFlags = worksiteUpdatedIds.flags {
                            let updatedIds = updatedFlags.map { f in
                                let localId = unsyncedLookup[f.reasonT]
                                return localId == nil || f.id > 0 ? f : f.copy { $0.id = localId! }
                            }
                            worksiteUpdatedIds = worksiteUpdatedIds.copy { $0.flags = updatedIds }
                        }
                    }

                    for record in updates {
                        try record.update(db, onConflict: .rollback)
                    }

                    syncLogger.log("Flags. Inserted \(inserts.count). Updated \(updates.count)")
                }

                for record in formData {
                    var record = record
                    try record.upsert(db)
                }
                syncLogger.log("Form data. Upserted \(formData.count).")

                if insertNotes.isNotEmpty {
                    var insertIds: [Int64] = []
                    for record in insertNotes {
                        var record = record
                        try record.insert(db, onConflict: .ignore)
                        insertIds.append(record.id!)
                    }
                    var insertedIndex = 0
                    worksiteUpdatedIds = worksiteUpdatedIds.copy {
                        $0.notes = $0.notes.map { note in
                            if note.id <= 0 {
                                if insertedIndex < insertNotes.count &&
                                    note.note == insertNotes[insertedIndex].note
                                {
                                    let insertId = insertIds[insertedIndex]
                                    insertedIndex += 1
                                    return note.copy { $0.id = insertId }
                                }
                            }
                            return note
                        }
                    }
                    syncLogger.log("Notes. Inserted \(insertNotes.count).")
                }

                try with(workTypes.split { $0.id == nil }) { workTypeRecordSplit in
                    let (inserts, updates) = workTypeRecordSplit
                    var insertIds: [Int64] = []
                    for record in inserts {
                        var record = record
                        try record.insert(db, onConflict: .ignore)
                        insertIds.append(record.id!)
                    }
                    let unsyncedLookup = inserts.enumerated()
                        .map { (index, w) in
                            let id = insertIds[index]
                            return id > 0 ? (w.workType, id) : nil
                        }
                        .filter { $0 != nil}
                        .associate { ($0!.0, $0!.1) }
                    if unsyncedLookup.isNotEmpty {
                        let updatedIds = worksiteUpdatedIds.workTypes.map { w in
                            let localId = unsyncedLookup[w.workTypeLiteral]
                            return localId == nil || w.id > 0 ? w : w.copy { $0.id = localId! }
                        }
                        worksiteUpdatedIds = worksiteUpdatedIds.copy { $0.workTypes = updatedIds }
                    }

                    for record in updates {
                        try record.update(db, onConflict: .rollback)
                    }

                    syncLogger.log("Work types. Inserted \(inserts.count). Updated \(updates.count)")
                }

                try db.saveWorksiteChange(
                    changeSerializer,
                    uuidGenerator,
                    worksiteStart: worksiteStart,
                    worksiteChange: worksiteUpdatedIds,
                    idMapping: idMapping,
                    appVersion: appVersionProvider.buildNumber,
                    organizationId: organizationId
                )

                return worksiteId
            }
        }
    }
}


fileprivate struct IdNetworkIdMaps {
    let flag: [Int64: Int64]
    let note: [Int64: Int64]
    let workType: [Int64: Int64]

    init(
        flag: [Int64 : Int64] = [:],
        note: [Int64 : Int64] = [:],
        workType: [Int64 : Int64] = [:]
    ) {
        self.flag = flag
        self.note = note
        self.workType = workType
    }
}
