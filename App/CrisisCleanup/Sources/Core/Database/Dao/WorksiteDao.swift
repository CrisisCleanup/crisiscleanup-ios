import Combine
import Foundation
import GRDB

public class WorksiteDao {
    private let database: AppDatabase
    private let reader: DatabaseReader
    private let syncLogger: SyncLogger

    init(
        _ database: AppDatabase,
        _ syncLogger: SyncLogger
    ) {
        self.database = database
        reader = database.reader

        self.syncLogger = syncLogger
    }

    private func throwSizeMismatch(
        _ worksitesSize: Int,
        _ size: Int,
        _ dataName: String
    ) throws {
        if worksitesSize != size {
            throw GenericError("Inconsistent data size. Each worksite must have corresponding \(dataName).")
        }
    }

    private func fetchWorksiteLocalModifiedAt(
        _ db: Database,
        _ networkWorksiteIds: Set<Int64>
    ) throws -> [Int64: WorksiteLocalModifiedAt] {
        let records = try WorksiteRootRecord
            .all()
            .networkIdsIn(networkWorksiteIds)
            .asRequest(of: WorksiteLocalModifiedAt.self)
            .fetchAll(db)
        return records.associateBy { $0.networkId }
    }

    /**
     * Syncs a worksite work types
     *
     * Deletes existing work types not specified and upserts work types specified.
     */
    private func syncWorkTypes(
        _ db: Database,
        _ worksiteId: Int64,
        _ unassociatedWorkTypes: [WorkTypeRecord]
    ) throws {
        if unassociatedWorkTypes.isEmpty {
            return
        }

        let worksiteWorkTypes = unassociatedWorkTypes.map { wt in wt.copy { $0.worksiteId = worksiteId } }
        let networkIds = worksiteWorkTypes.map { $0.networkId }
        try WorkTypeRecord.syncDeleteUnspecified(db, worksiteId, networkIds)
        for workType in worksiteWorkTypes {
            try workType.syncUpsert(db)
        }
    }

    private func syncFormData(
        _ db: Database,
        _ worksiteId: Int64,
        _ unassociatedFormData: [WorksiteFormDataRecord]
    ) throws {
        if unassociatedFormData.isEmpty {
            return
        }

        let worksiteFormData = unassociatedFormData.map { fd in fd.copy { $0.worksiteId = worksiteId } }
        let fieldKeys = Set(worksiteFormData.map { $0.fieldKey })
        try WorksiteFormDataRecord.deleteUnspecifiedKeys(db, worksiteId, fieldKeys)
        for formData in worksiteFormData {
            var formData = formData
            try formData.upsert(db)
        }
    }

    private func syncFlags(
        _ db: Database,
        _ worksiteId: Int64,
        _ unassociatedFlags: [WorksiteFlagRecord]
    ) throws {
        let flags = unassociatedFlags.map { f in f.copy { $0.worksiteId = worksiteId} }
        let reasons = flags.map { $0.reasonT }
        try WorksiteFlagRecord.syncDeleteUnspecified(db, worksiteId, reasons)
        for flag in flags {
            var flag = flag
            try flag.upsert(db)
        }
    }

    private func syncNotes(
        _ db: Database,
        _ worksiteId: Int64,
        _ unassociatedNotes: [WorksiteNoteRecord]
    ) throws {
        if unassociatedNotes.isEmpty {
            return
        }

        let notes = unassociatedNotes.map { n in n.copy { $0.worksiteId = worksiteId } }
        let networkIds = notes.map { $0.networkId }
        try WorksiteNoteRecord.syncDeleteUnspecified(db, worksiteId, networkIds)
        for note in notes {
            try note.syncUpsert(db)
        }
    }

    // TODO: Finish tests
    private func syncFiles(
        _ db: Database,
        _ worksiteId: Int64,
        _ files: [NetworkFileRecord]
    ) throws {
        if files.isEmpty {
            return
        }

        for record in files {
            try record.upsert(db)
        }
        let ids = Set(files.map { $0.id })
        try NetworkFileRecord.deleteDeleted(db, worksiteId, ids)
        try WorksiteToNetworkFileRecord.deleteUnspecified(db, worksiteId, ids)
        for networkFileId in ids {
            try WorksiteToNetworkFileRecord(
                id: worksiteId,
                networkFileId: networkFileId
            ).insert(db, onConflict: .ignore)
        }
    }

    private func syncWorksite(
        _ db: Database,
        _ worksite: WorksiteRecord,
        _ modifiedAt: WorksiteLocalModifiedAt?,
        _ workTypes: [WorkTypeRecord],
        _ syncedAt: Date,
        formData: [WorksiteFormDataRecord]? = nil,
        flags: [WorksiteFlagRecord]? = nil,
        notes: [WorksiteNoteRecord]? = nil,
        files: [NetworkFileRecord]? = nil,
        // TODO: Test coverage
        keepKeyWorkType: Bool = false
    ) throws -> Bool {
        let isLocallyModified = modifiedAt?.isLocalModified ?? false
        if modifiedAt == nil {
            let id = try WorksiteRootRecord.insertOrRollback(
                db,
                syncedAt,
                worksite.networkId,
                worksite.incidentId
            )
            var worksite = worksite.copy { $0.id = id }
            try worksite.insert(db)

            try syncWorkTypes(db, id, workTypes)
            if let formData = formData { try syncFormData(db, id, formData) }
            if let flags = flags { try syncFlags(db, id, flags) }
            if let notes = notes { try syncNotes(db, id, notes) }
            if let files = files { try syncFiles(db, id, files) }

            return true

        } else if !isLocallyModified {
            try WorksiteRootRecord.syncUpdate(
                db,
                id: modifiedAt!.id,
                expectedLocalModifiedAt: modifiedAt!.localModifiedAt,
                syncedAt: syncedAt,
                networkId: worksite.networkId,
                incidentId: worksite.incidentId
            )
            try worksite.copy {
                $0.id = modifiedAt!.id
                $0.incidentId = worksite.incidentId
                $0.keyWorkTypeType = keepKeyWorkType ? "" : $0.keyWorkTypeType
                $0.keyWorkTypeOrgClaim = keepKeyWorkType ? -1 : $0.keyWorkTypeOrgClaim
                $0.keyWorkTypeStatus = keepKeyWorkType ? "" : $0.keyWorkTypeStatus
            }.syncUpdateWorksite(db)

            // Should return a valid ID if UPDATE OR ROLLBACK query succeeded
            let worksiteId = try WorksiteRecord.getWorksiteId(db, worksite.networkId)!

            try syncWorkTypes(db, worksiteId, workTypes)
            if let formData = formData { try syncFormData(db, worksiteId, formData) }
            if let flags = flags { try syncFlags(db, worksiteId, flags) }
            if let notes = notes { try syncNotes(db, worksiteId, notes) }
            if let files = files { try syncFiles(db, worksiteId, files) }

            return true

        } else {
            // Resolving changes at this point is not worth the complexity.
            // Defer to worksite (snapshot) changes resolving successfully and completely.
            syncLogger.log("Skip sync overwriting locally modified worksite \(modifiedAt!.id) (\(worksite.networkId))")
        }

        return false
    }

    // internal for testing. Should be fileprivate.
    internal func syncFillWorksite(
        _ db: Database,
        _ records: WorksiteRecords
    ) throws -> Bool {
        let core = records.core
        let flags = records.flags
        let formData = records.formData
        let notes = records.notes
        let workTypes = records.workTypes
        let files = records.files

        let worksiteId = try WorksiteRecord.getWorksiteId(db, core.networkId)
        if worksiteId != nil && worksiteId! > 0 {
            let worksiteId = worksiteId!
            try WorksiteRecord.syncFillWorksite(
                db,
                worksiteId,
                autoContactFrequencyT: core.autoContactFrequencyT,
                caseNumber: core.caseNumber,
                email: core.email,
                favoriteId: core.favoriteId,
                phone1: core.phone1,
                phone2: core.phone2,
                plusCode: core.plusCode,
                svi: core.svi,
                reportedBy: core.reportedBy,
                what3Words: core.what3Words
            )

            let flagsReasons = Set(try WorksiteFlagRecord.getReasons(db, worksiteId))
            let newFlags = flags.filter { flag in !flagsReasons.contains(flag.reasonT) }
                .map { flag in flag.copy { $0.worksiteId = worksiteId } }
            for flag in newFlags {
                var flag = flag
                try flag.insert(db, onConflict: .ignore)
            }

            let formDataKeys = Set(try WorksiteFormDataRecord.getDataKeys(db, worksiteId))
            let newFormData = formData.filter { data in !formDataKeys.contains(data.fieldKey) }
                .map { data in data.copy { $0.worksiteId = worksiteId } }
            for formData in newFormData {
                var formData = formData
                try formData.upsert(db)
            }

            let recentNotes = Set(try WorksiteNoteRecord.getNotes(db, worksiteId).map { $0.trim() })
            let newNotes = notes.filter { note in !recentNotes.contains(note.note) }
                .map { note in note.copy { $0.worksiteId = worksiteId } }
            for note in newNotes {
                var note = note
                try note.insert(db, onConflict: .ignore)
            }

            let workTypeKeys = Set(try WorkTypeRecord.getWorkTypes(db, worksiteId))
            let newWorkTypes = workTypes.filter { wt in !workTypeKeys.contains(wt.workType) }
                .map { wt in wt.copy { $0.worksiteId = worksiteId } }
            for workType in newWorkTypes {
                var workType = workType
                try workType.insert(db, onConflict: .ignore)
            }

            try syncFiles(db, worksiteId, files)

            return true
        }
        return false
    }

    func syncNetworkWorksite(
        _ records: WorksiteRecords,
        _ syncedAt: Date
    ) async throws -> Bool {
        try await database.syncWorksite(self, records, syncedAt)
    }

    func syncWorksites(
        _ worksitesRecords: [WorksiteRecords],
        _ syncedAt: Date
    ) async throws {
        for records in worksitesRecords {
            _  = try await syncNetworkWorksite(records, syncedAt)
        }
    }

    /**
     * Syncs worksite data skipping worksites where local changes exist
     *
     * - Returns: Number of worksites inserted/updated
     */
    func syncWorksites(
        _ worksites: [WorksiteRecord],
        _ worksitesWorkTypes: [[WorkTypeRecord]],
        _ syncedAt: Date
    ) async throws {
        try throwSizeMismatch(worksites.count, worksitesWorkTypes.count, "work types")

        let networkWorksiteIds = Set(worksites.map { $0.networkId })

        try await database.dbWriter.write { db in
            let modifiedAtLookup = try self.fetchWorksiteLocalModifiedAt(db, networkWorksiteIds)

            try worksites.enumerated().forEach { (i, worksite) in
                let workTypes = worksitesWorkTypes[i]
                let modifiedAt = modifiedAtLookup[worksite.networkId]
                _ = try self.syncWorksite(
                    db,
                    worksite,
                    modifiedAt,
                    workTypes,
                    syncedAt
                )
            }
        }
    }

    // TODO: Write tests
    func syncShortFlags(
        _ worksites: [WorksiteRecord],
        _ worksitesFlags: [[WorksiteFlagRecord]]
    ) async throws {
        try throwSizeMismatch(worksites.count, worksitesFlags.count, "flags")

        let networkWorksiteIds = Set(worksites.map { $0.networkId })
        try await database.dbWriter.write { db in
            let modifiedAtLookup = try self.fetchWorksiteLocalModifiedAt(db, networkWorksiteIds)

            for (i, flags) in worksitesFlags.enumerated() {
                let networkWorksiteId = worksites[i].networkId
                let modifiedAt = modifiedAtLookup[networkWorksiteId]
                let isLocallyModified = modifiedAt?.isLocalModified ?? false
                if !isLocallyModified {
                    let worksiteId = try WorksiteRecord.getWorksiteId(db, networkWorksiteId)!
                    let flagReasons = flags.map { $0.reasonT }
                    try WorksiteFlagRecord.syncDeleteUnspecified(db, worksiteId, flagReasons)
                    let updatedFlags = flags.map { flag in flag.copy { $0.worksiteId = worksiteId } }
                    for flag in updatedFlags {
                        var flag = flag
                        try flag.insert(db, onConflict: .ignore)
                    }
                }
            }
        }
    }

    private func fetchWorksiteId(
        _ db: Database,
        _ networkId: Int64
    ) throws -> Int64 {
        try WorksiteRootRecord
            .all()
            .byUnique(networkId)
            .fetchOne(db)!
            .id!
    }

    internal func syncWorksite(
        _ db: Database,
        _ records: WorksiteRecords,
        _ syncedAt: Date
    ) throws -> (Bool, Int64) {
        let core = records.core
        let idSet: Set = [core.networkId]
        let modifiedAtLookup = try fetchWorksiteLocalModifiedAt(db, idSet)
        let modifiedAt = modifiedAtLookup[core.networkId]
        let isUpdated = try syncWorksite(
            db,
            core,
            modifiedAt,
            records.workTypes,
            syncedAt,
            formData: records.formData,
            flags: records.flags,
            notes: records.notes,
            files: records.files,
            keepKeyWorkType: true
        )

        let worksiteId = isUpdated ? try fetchWorksiteId(db, core.networkId)
        : -1
        return (isUpdated, worksiteId)
    }

    func streamIncidentWorksitesCount(_ id: Int64) -> AnyPublisher<Int, Error> {
        ValueObservation
            .tracking({ db in try self.fetchIncidentWorksitesCount(db, id) })
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    func getWorksitesCount(_ incidentId: Int64) throws -> Int {
        return try reader.read({ db in try self.fetchIncidentWorksitesCount(db, incidentId) })
    }

    private func fetchIncidentWorksitesCount(_ db: Database, _ incidentId: Int64) throws -> Int {
        try WorksiteRootRecord.getCount(db, incidentId)
    }

    func getWorksitesCount(
        _ incidentId: Int64,
        south: Double,
        north: Double,
        west: Double,
        east: Double
    ) throws -> Int {
        return try reader.read({ db in
            try WorksiteRecord.getCount(
                db,
                incidentId,
                south: south,
                north: north,
                west: west,
                east: east
            )
        })
    }

    func getWorksiteId(_ networkId: Int64) throws -> Int64 {
        try reader.read { db in
            try WorksiteRootRecord.getWorksiteId(db, networkId)
        }
    }

    func getWorksitesMapVisual(
        _ incidentId: Int64,
        south: Double,
        north: Double,
        west: Double,
        east: Double,
        limit: Int,
        offset: Int
    ) throws -> [WorksiteMapMark] {
        try reader.read { db in
            let worksiteAlias = TableAlias(name: "w")
            let worksiteColumns = WorksiteRootRecord.worksite
                .select(WorksiteRecord.visualColumns)
                .aliased(worksiteAlias)
            let request = WorksiteRootRecord
                .all()
                .selectIdColumn()
                .byIncidentId(incidentId)
                .including(required: worksiteColumns
                    .byBounds(
                        alias: worksiteAlias,
                        south: south,
                        north: north,
                        west: west,
                        east: east
                    )
                        .orderByUpdatedAtDescIdDesc()
                )
                .including(all: WorksiteRootRecord.worksiteFlags)
                .annotated(with: WorksiteRootRecord.workTypes.count)
                .limit(limit, offset: offset)
                .asRequest(of: PopulatedWorksiteMapVisual.self)
            return try request.fetchAll(db)
        }.map { record in record.asExternalModel() }
    }

    func getWorksite(_ id: Int64) throws -> PopulatedLocalWorksite? {
        try reader.read { db in try fetchLocalWorksite(db, id) }
    }

    func streamLocalWorksite(_ id: Int64) -> AnyPublisher<PopulatedLocalWorksite?, Error> {
        ValueObservation
            .tracking({ db in try self.fetchLocalWorksite(db, id) })
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    private func fetchLocalWorksite(_ db: Database, _ id: Int64) throws -> PopulatedLocalWorksite? {
        try WorksiteRootRecord
            .filter(id: id)
            .including(required: WorksiteRootRecord.worksite)
            .including(all: WorksiteRootRecord.worksiteFlags)
            .including(all: WorksiteRootRecord.worksiteFormData)
            .including(all: WorksiteRootRecord.worksiteNotes)
            .including(all: WorksiteRootRecord.workTypes)
            .including(all: WorksiteRootRecord.networkFiles
                .including(optional: NetworkFileRecord.networkFileLocalImage))
            .including(all: WorksiteRootRecord.worksiteLocalImages)
            .asRequest(of: PopulatedLocalWorksite.self)
            .fetchOne(db)
    }

    func getWorksiteNetworkId(_ worksiteId: Int64) -> Int64 {
        try! reader.read { db in
            try WorksiteRecord
                .filter(id: worksiteId)
                .selectNetworkId()
                .asRequest(of: Int64.self)
                .fetchOne(db)!
        }
    }

    func getIncidentId(_ worksiteId: Int64) -> Int64 {
        try! reader.read { db in
            try WorksiteRecord
                .filter(id: worksiteId)
                .selectIncidentId()
                .asRequest(of: Int64.self)
                .fetchOne(db)!
        }
    }

    func onSyncEnd(
        _ worksiteId: Int64,
        _ syncLogger: SyncLogger,
        _ syncedAt: Date = Date.now) async throws -> Bool {
        try await database.onSyncEnd(worksiteId, syncLogger, syncedAt)
    }

    func getLocallyModifiedWorksites(_ limit: Int) throws -> [Int64] {
        try reader.read { db in
            try WorksiteRootRecord
                .all()
                .selectIdColumn()
                .filterLocalModified()
                .orderedByLocalModifiedAtDesc()
                .limit(limit)
                .asRequest(of: Int64.self)
                .fetchAll(db)
        }
    }

    func getUnsyncedChangeCount(_ worksiteId: Int64) throws -> [Int] {
        try reader.read { db in
            return [
                try WorksiteFlagRecord.getUnsyncedCount(db, worksiteId),
                try WorksiteNoteRecord.getUnsyncedCount(db, worksiteId),
                try WorkTypeRecord.getUnsyncedCount(db, worksiteId),
                try WorksiteChangeRecord.getUnsyncedCount(db, worksiteId),
            ]
        }
    }

    // MARK: - Test access

    internal func getLocalWorksite(_ id: Int64) throws -> PopulatedLocalWorksite? {
        try reader.read { db in try self.fetchLocalWorksite(db, id) }
    }

    internal func getPopulatedWorksite(_ id: Int64) throws -> PopulatedWorksite? {
        try reader.read { db in
            try WorksiteRootRecord
                .filter(id: id)
                .including(required: WorksiteRootRecord.worksite)
                .including(all: WorksiteRootRecord.workTypes)
                .asRequest(of: PopulatedWorksite.self)
                .fetchOne(db)
        }
    }

    internal func getWorksites(_ incidentId: Int64) throws -> [PopulatedWorksite] {
        try reader.read { db in
            try WorksiteRootRecord
                .all()
                .byIncidentId(incidentId)
                .including(required: WorksiteRootRecord.worksite.orderByUpdatedAtDescIdDesc())
                .including(all: WorksiteRootRecord.workTypes)
                .asRequest(of: PopulatedWorksite.self)
                .fetchAll(db)
        }
    }
}

extension AppDatabase {
    fileprivate func syncWorksite(
        _ worksiteDao: WorksiteDao,
        _ records: WorksiteRecords,
        _ syncedAt: Date
    ) async throws -> Bool {
        return try await dbWriter.write { db in
            let (isSynced, _) = try worksiteDao.syncWorksite(db, records, syncedAt)
            if !isSynced {
                _ = try worksiteDao.syncFillWorksite(db, records)
            }
            return isSynced
        }
    }

    fileprivate func onSyncEnd(
        _ worksiteId: Int64,
        _ syncLogger: SyncLogger,
        _ syncedAt: Date
    ) async throws -> Bool {
        try await dbWriter.write { db in
            let flagChanges = try db.getUnsyncedFlagCount(worksiteId)
            let noteChanges = try db.getUnsyncedNoteCount(worksiteId)
            let workTypeChanges = try db.getUnsyncedWorkTypeCount(worksiteId)
            let changes = try db.getWorksiteChangeCount(worksiteId)
            let hasModification = flagChanges > 0 ||
            noteChanges > 0 ||
            workTypeChanges > 0 ||
            changes > 0
            if hasModification {
                syncLogger.log(
                    "Pending changes on sync end",
                    details: "flag: \(flagChanges)\nnote: \(noteChanges)\nwork type: \(workTypeChanges)\nchanges: \(changes)")
                return false
            }
            try db.setWorksiteRootUnmodified(worksiteId, syncedAt)
            try db.deleteUnsyncedWorkTypeTransferRequests(worksiteId)
            return true
        }
    }
}

extension Database {
    fileprivate func setWorksiteRootUnmodified(_ worksiteId: Int64, _ syncedAt: Date) throws {
        try WorksiteRootRecord.setRootUnmodified(self, worksiteId, syncedAt)
    }
}
