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
        let fieldKeys = worksiteFormData.map { $0.fieldKey }
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

    // TODO: Write tests
    private func syncFiles(
        _ db: Database,
        _ worksiteId: Int64,
        _ files: [NetworkFileRecord]
    ) throws {
        if files.isEmpty {
            return
        }

        // TODO: Do. Ensure there is test coverage if upserting
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
            _ = syncLogger.log("Skip sync overwriting locally modified worksite \(modifiedAt!.id) (\(worksite.networkId))")
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
            .publisher(in: reader)
            .share()
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

    // MARK: - Test access

    internal func getLocalWorksite(_ id: Int64) throws -> PopulatedLocalWorksite? {
        try reader.read { db in
        try WorksiteRootRecord
            .filter(id: id)
            .including(required: WorksiteRootRecord.worksite)
            .including(all: WorksiteRootRecord.worksiteFlags)
            .including(all: WorksiteRootRecord.worksiteFormData)
            .including(all: WorksiteRootRecord.worksiteNotes)
            .including(all: WorksiteRootRecord.workTypes)
            .asRequest(of: PopulatedLocalWorksite.self)
            .fetchOne(db)
        }
    }

    internal func getWorksite(_ id: Int64) throws -> PopulatedWorksite? {
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
}

// MARK: - Requests

internal struct PopulatedWorksite: Equatable, Decodable, FetchableRecord {
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let workTypes: [WorkTypeRecord]

    func asExternalModel() -> Worksite {
        let keyWorkType = workTypes
            .first(where: {
                $0.workType == worksite.keyWorkTypeType
            })?.asExternalModel()
        return Worksite(
            id: worksite.id!,
            address: worksite.address,
            autoContactFrequencyT: worksite.autoContactFrequencyT ?? "",
            caseNumber: worksite.caseNumber,
            city: worksite.city,
            county: worksite.county,
            createdAt: worksite.createdAt,
            favoriteId: worksite.favoriteId,
            incidentId: worksite.incidentId,
            keyWorkType: keyWorkType,
            latitude: worksite.latitude,
            longitude: worksite.longitude,
            name: worksite.name,
            networkId: worksite.networkId,
            phone1: worksite.phone1 ?? "",
            phone2: worksite.phone2 ?? "",
            postalCode: worksite.postalCode,
            reportedBy: worksite.reportedBy,
            state: worksite.state,
            svi: worksite.svi,
            updatedAt: worksite.updatedAt,
            workTypes: workTypes.map { $0.asExternalModel() },
            isAssignedToOrgMember: worksiteRoot.isLocalModified ? worksite.isLocalFavorite : worksite.favoriteId != nil
        )
    }
}

struct WorksiteLocalModifiedAt: Equatable, Decodable, FetchableRecord {
    let id: Int64
    let networkId: Int64
    let localModifiedAt: Date
    let isLocalModified: Bool
}

internal struct PopulatedLocalWorksite: Equatable, Decodable, FetchableRecord {
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let worksiteFlags: [WorksiteFlagRecord]
    let worksiteFormData: [WorksiteFormDataRecord]
    let worksiteNotes: [WorksiteNoteRecord]
    let workTypes: [WorkTypeRecord]

    func asExternalModel(
        _ orgId: Int64,
        _ translator: KeyTranslator? = nil
    ) -> LocalWorksite {
        let keyWorkType = workTypes
            .first(where: {
                $0.workType == worksite.keyWorkTypeType
            })?.asExternalModel()
        let formDataLookup = worksiteFormData.associate { ($0.fieldKey, $0.asExternalModel()) }
        return LocalWorksite(
            worksite: Worksite(
                id: worksite.id!,
                address: worksite.address,
                autoContactFrequencyT: worksite.autoContactFrequencyT ?? "",
                caseNumber: worksite.caseNumber,
                city: worksite.city,
                county: worksite.county,
                createdAt: worksite.createdAt,
                favoriteId: worksite.favoriteId,
                // TODO: Do
                // files: ,
                flags: worksiteFlags.map { $0.asExternalModel(translator) },
                formData: formDataLookup,
                incidentId: worksite.incidentId,
                keyWorkType: keyWorkType,
                latitude: worksite.latitude,
                longitude: worksite.longitude,
                name: worksite.name,
                networkId: worksite.networkId,
                notes: worksiteNotes
                    .filter { $0.note.isNotBlank }
                    .sorted(by: { a, b in
                        if a.networkId == b.networkId {
                            return a.createdAt >= b.createdAt
                        }
                        return  {
                            if a.networkId < 0 { return true }
                                else if b.networkId < 0 { return false }
                                else { return a.networkId > b.networkId }
                        }()
                    })
                    .map { $0.asExternalModel() },
                phone1: worksite.phone1 ?? "",
                phone2: worksite.phone2 ?? "",
                postalCode: worksite.postalCode,
                reportedBy: worksite.reportedBy,
                state: worksite.state,
                svi: worksite.svi,
                updatedAt: worksite.updatedAt,
                workTypes: workTypes.map { $0.asExternalModel() },
                // TODO: Do
                workTypeRequests: [],
                isAssignedToOrgMember: worksiteRoot.isLocalModified ? worksite.isLocalFavorite : worksite.favoriteId != nil
            ),
            // TODO: Do
            localImages: [],
            localChanges: LocalChange(
                isLocalModified: worksiteRoot.isLocalModified,
                localModifiedAt: worksiteRoot.localModifiedAt,
                syncedAt: worksiteRoot.syncedAt
            )
        )
    }
}
