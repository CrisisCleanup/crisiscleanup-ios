import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteChangeDaoTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)
    private var createdAtA = Date.now
    private var updatedAtA = Date.now
    private var createdAtB = Date.now
    private var updatedAtB = Date.now
    private var createdAtC = Date.now

    private var dbQueue: DatabaseQueue? = nil
    private var appDb: AppDatabase? = nil
    private var worksiteChangeDao: WorksiteChangeDao? = nil

    private var testIncidentId: Int64 = 0

    private var uuidGenerator: UuidGenerator = TestUuidGenerator()
    private var changeSerializer: WorksiteChangeSerializerMock!

    override func setUp() async throws {
        createdAtA = now.addingTimeInterval(-4.days)
        updatedAtA = createdAtA.addingTimeInterval(40.minutes)
        createdAtB = createdAtA.addingTimeInterval(1.days)
        updatedAtB = createdAtB.addingTimeInterval(51.minutes)
        createdAtC = createdAtB.addingTimeInterval(23.hours)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        uuidGenerator = TestUuidGenerator()
        changeSerializer = .init()
        worksiteChangeDao = WorksiteChangeDao(
            appDb!,
            uuidGenerator: uuidGenerator,
            changeSerializer: changeSerializer,
            appVersionProvider: WorksiteTestUtil.testAppVersionProvider,
            syncLogger: WorksiteTestUtil.silentSyncLogger
        )

        try await dbQueue!.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }

        testIncidentId = WorksiteTestUtil.testIncidents.last!.id
    }

    /**
     * Flags are
     * - 0, reason-a
     * - 33, reason-b
     *
     * Notes are
     * - 0, note-a, atA
     * - 64, note-b, atB
     *
     * Work types are
     * - 0, work-type-a, atA, status-a, nil
     * - 57, work-type-b, atB, status-b, 523
     */
    private func makeFullWorksite() -> Worksite {
        Worksite(
            id: 56,
            address: "address",
            autoContactFrequencyT: AutoContactFrequency.notOften.literal,
            caseNumber: "case-number",
            city: "city",
            county: "county",
            createdAt: createdAtA,
            email: "email",
            favoriteId: 623,
            flags: [
                testWorksiteFlag(
                    0,
                    createdAtA,
                    "reason-a"
                ),
                testWorksiteFlag(
                    33,
                    createdAtB,
                    "reason-b",
                    isHighPriority: true
                ),
            ],
            formData: [
                "form-data-bt": WorksiteFormValue(isBoolean: true, valueString: "", valueBoolean: true),
                "form-data-sa": WorksiteFormValue(isBoolean: false, valueString: "form-data-value-a"),
                "form-data-bf": WorksiteFormValue(isBoolean: true, valueString: "", valueBoolean: false),
            ],
            incidentId: testIncidentId,
            keyWorkType: nil,
            latitude: -5.23,
            longitude: -39.35,
            name: "name",
            networkId: -1,
            notes: [
                testWorksiteNote(0, createdAtA, "note-a"),
                testWorksiteNote(64, createdAtB, "note-b"),
            ],
            phone1: "phone1",
            phone2: "phone2",
            plusCode: "plus-code",
            postalCode: "postal-code",
            reportedBy: 573,
            state: "state",
            svi: 0.5,
            updatedAt: updatedAtA,
            what3Words: "what-3-words",
            workTypes: [
                testWorkType(
                    0,
                    createdAtA,
                    nil,
                    "status-a",
                    "work-type-a"
                ),
                testWorkType(
                    57,
                    createdAtB,
                    523,
                    "status-b",
                    "work-type-b"
                ),
            ],
            isAssignedToOrgMember: true
        )
    }

    /**
     * Flags are
     * - 1, reason-a
     * - 11, reason-c
     * - 0, reason-d
     *
     * Notes are
     * - 1, note-a, atA
     * - 64, note-b, atB
     * - 0, note-c, atC
     * - 0, note-d, atC
     * - 41, note-e, atB
     *
     * Work types are
     * - 1, work-type-a, atA, status-a-change, nil
     * - 0, work-type-d, atC, status-d, 523
     */
    private func changeFullWorksite() -> Worksite {
        makeFullWorksite().copy {
            $0.address = "address-change"
            $0.autoContactFrequencyT = AutoContactFrequency.often.literal
            $0.city = "city-change"
            $0.county = "county-change"
            $0.email = "email-change"
            $0.favoriteId = nil
            $0.flags = [
                // Update createdAt (from full)
                testWorksiteFlag(
                    1,
                    createdAtC,
                    "reason-a"
                ),
                // Delete 33 (from full)
                // Insert and map 11 (network ID)
                testWorksiteFlag(
                    11,
                    createdAtB,
                    "reason-c"
                ),
                // Add
                testWorksiteFlag(
                    0,
                    createdAtB,
                    "reason-d"
                ),
            ]
            $0.formData = [
                // Delete form-data-bt  (from full)
                // Change  (from full)
                "form-data-sa": WorksiteFormValue(isBoolean: false, valueString: "form-data-value-change-a"),
                // No-op
                "form-data-bf": WorksiteFormValue(isBoolean: true, valueString: "", valueBoolean: false),
                // Add
                "form-data-new-c": WorksiteFormValue(isBoolean: false, valueString: "form-data-new-c"),
                "form-data-new-d": WorksiteFormValue(isBoolean: true, valueString: "", valueBoolean: false),
            ]
            $0.latitude = 15.23
            $0.longitude = -319.08
            $0.name = "name-change"
            $0.networkId = -1
            $0.notes = [
                // Notes are not mutable
                testWorksiteNote(1, createdAtA, "note-a"),
                testWorksiteNote(64, createdAtB, "note-b"),
                // Add
                testWorksiteNote(0, createdAtC, "note-c"),
                testWorksiteNote(0, createdAtC, "note-d"),
                // Insert and map 41
                testWorksiteNote(41, createdAtB, "note-e"),
            ]
            $0.phone1 = "phone1-change"
            $0.phone2 = ""
            $0.postalCode = "postal-code-change"
            $0.state = "state-change"
            $0.updatedAt = updatedAtB
            $0.workTypes = [
                // Update (from full)
                testWorkType(
                    1,
                    createdAtA,
                    nil,
                    "status-a-change",
                    "work-type-a"
                ),
                // Delete 57  (from full)
                // Add
                testWorkType(
                    0,
                    createdAtC,
                    523,
                    "status-d",
                    "work-type-d"
                ),
            ]
            $0.isAssignedToOrgMember = false
        }
    }

    internal static func insertWorksite(
        _ dbQueue: DatabaseQueue,
        _ uuidGenerator: UuidGenerator,
        _ now: Date,
        _ worksite: Worksite) async throws -> EditWorksiteRecords {
        let records = worksite.asRecords(
            uuidGenerator,
            worksite.workTypes[0],
            flagIdLookup: [:],
            noteIdLookup: [:],
            workTypeIdLookup: [:]
        )

        let inserted = try await WorksiteTestUtil.insertWorksites(dbQueue, now, [records.core])
        let worksiteId = inserted[0].id!
        return try await dbQueue.write { db in
            let flags = records.flags.map { f in f.copy { $0.worksiteId = worksiteId } }
            for record in flags {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }
            let formData = records.formData.map { f in f.copy{ $0.worksiteId = worksiteId } }
            for record in formData {
                var record = record
                try record.upsert(db)
            }
            let notes = records.notes.map { n in n.copy { $0.worksiteId = worksiteId } }
            for record in notes {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }
            let workTypes = records.workTypes.map { w in w.copy { $0.worksiteId = worksiteId } }
            for record in workTypes {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }

            let worksiteRecord = records.core.copy { $0.id = worksiteId }
            return EditWorksiteRecords(
                core: worksiteRecord,
                flags: flags,
                formData: formData,
                notes: notes,
                workTypes: workTypes
            )
        }
    }

    private func insertWorksite(_ worksite: Worksite) async throws -> EditWorksiteRecords {
        try await WorksiteChangeDaoTests.insertWorksite(dbQueue!, uuidGenerator, now, worksite)
    }

    private func expectedFormData(
        _ formData: [WorksiteFormDataRecord],
        worksiteId: Int64? = nil
    ) -> [WorksiteFormDataRecord] {
        var recordIndex: Int64 = 1
        var expectedFormData = formData

        if let wid = worksiteId {
            expectedFormData = expectedFormData.map { f in
                f.copy { $0.worksiteId = wid }
            }
        }
        return expectedFormData.map { fd in
            let copy = fd.copy { $0.id = recordIndex }
            recordIndex += 1
            return copy
        }
    }

    func testSkipUnchanged() async throws {
        let worksiteFull = makeFullWorksite()
        let entityData = try await insertWorksite(worksiteFull)

        let worksiteChanged = changeFullWorksite()
        _ = try await worksiteChangeDao!.saveChange(
            worksiteStart: worksiteChanged,
            worksiteChange: worksiteChanged,
            primaryWorkType: worksiteChanged.workTypes[0],
            organizationId: 385
        )

        let worksiteEntity = entityData.core
        let worksiteId = worksiteEntity.id!
        let actualWorksite = try await dbQueue!.read { db in
            try WorksiteRecord
                .filter(id: worksiteId)
                .fetchOne(db)
        }
        XCTAssertEqual(worksiteEntity, actualWorksite)

        var entityIndex: Int64 = 1
        let expectedFlags = entityData.flags.map { flag in
            var flag = flag
            if flag.id == nil {
                flag = flag.copy { $0.id = entityIndex }
                entityIndex += 1
            }
            return flag
        }
        let actualFlags = try dbQueue!.selectWorksiteFlags(worksiteId)
        XCTAssertEqual(expectedFlags, actualFlags)

        entityIndex = 1
        let expectedFormData = expectedFormData(entityData.formData)
        let actualFormData = try dbQueue!.selectWorksiteFormData(worksiteId)
        XCTAssertEqual(expectedFormData, actualFormData)

        entityIndex = 1
        let expectedNotes = entityData.notes.map { note in
            var note = note
            if note.id == nil {
                note = note.copy { $0.id = entityIndex }
                entityIndex += 1
            }
            return note
        }
        let actualNotes = try dbQueue!.selectWorksiteNotes(worksiteId)
            .sorted(by: { a, b in a.id! < b.id! })
        XCTAssertEqual(expectedNotes, actualNotes)

        entityIndex = 1
        let expectedWorkTypes = entityData.workTypes.map { workType in
            var workType = workType
            if workType.id == nil {
                workType = workType.copy { $0.id = entityIndex }
                entityIndex += 1
            }
            return workType
        }
        let actualWorkTypes = try dbQueue!.selectWorksiteWorkTypes(worksiteId)
        XCTAssertEqual(expectedWorkTypes, actualWorkTypes)

        XCTAssertFalse(changeSerializer.serializeCalled)
    }

    func testNewWorksite() async throws {
        let worksiteFull = makeFullWorksite()
        let newFlags = worksiteFull.flags!.map { f in f.copy { $0.id = 0 } }
        let newNotes = worksiteFull.notes.map { n in n.copy { $0.id = 0 } }
        let newWorkTypes = worksiteFull.workTypes.map { w in w.copy { $0.id = 0 } }
        let newWorksite = worksiteFull.copy {
            $0.id = 0
            $0.networkId = -1
            $0.flags = newFlags
            $0.notes = newNotes
            $0.workTypes = newWorkTypes
        }

        let primaryWorkType = newWorksite.workTypes[0]
        let records = newWorksite.asRecords(
            uuidGenerator,
            primaryWorkType,
            flagIdLookup: [:],
            noteIdLookup: [:],
            workTypeIdLookup: [:]
        )

        changeSerializer.mockClosure(
            true,
            EmptyWorksite,
            newWorksite.copy {
                $0.id = 1
                $0.flags = newFlags.enumerated().map { (index, flag) in flag.copy { $0.id = Int64(index + 1) } }
                $0.notes = newNotes.enumerated().map { (index, note) in note.copy { $0.id = Int64(index + 1) } }
                $0.workTypes = newWorkTypes.enumerated().map { (index, workType) in workType.copy { $0.id = Int64(index + 1) } }
            },
            nil,
            nil,
            nil,
            mockReturn: (2, "serialized-new-worksite-changes")
        )

        _ = try await worksiteChangeDao!.saveChange(
            worksiteStart: EmptyWorksite,
            worksiteChange: newWorksite,
            primaryWorkType: primaryWorkType,
            organizationId: 385,
            localModifiedAt: now
        )

        let worksiteRecord = records.core.copy { $0.id = 1 }
        let worksiteId = worksiteRecord.id!

        let actualRoot = try dbQueue!.selectWorksiteRoot(worksiteId)
        let expectedRoot = WorksiteRootRecord(
            id: 1,
            syncUuid: "uuid-5",
            localModifiedAt: now,
            syncedAt: epoch0,
            localGlobalUuid: "uuid-6",
            isLocalModified: true,
            syncAttempt: 0,
            networkId: -1,
            incidentId: testIncidentId
        )
        XCTAssertEqual(expectedRoot, actualRoot)

        let actualWorksite = try dbQueue!.selectWorksite(worksiteId)
        XCTAssertEqual(worksiteRecord, actualWorksite)

        var recordIndex: Int64 = 1

        let expectedFlags = records.flags.map { f in
            f.copy {
                $0.id = recordIndex
                recordIndex += 1
                $0.worksiteId = 1
            }
        }
        let actualFlags = try dbQueue!.selectWorksiteFlags(worksiteId)
        XCTAssertEqual(expectedFlags, actualFlags)

        recordIndex = 1
        let expectedFormData = expectedFormData(records.formData, worksiteId: 1)
        let actualFormData = try dbQueue!.selectWorksiteFormData(worksiteId)
        XCTAssertEqual(expectedFormData, actualFormData)

        recordIndex = 1
        var localGlobalIndex = 3
        let expectedNotes = records.notes.map { n in
            n.copy {
                $0.id = recordIndex
                recordIndex += 1
                $0.worksiteId = 1
                $0.localGlobalUuid = "uuid-\(localGlobalIndex)"
                localGlobalIndex += 1
            }
        }
        let actualNotes = try dbQueue!.selectWorksiteNotes(worksiteId)
            .sorted(by: { a, b in a.createdAt < b.createdAt })
        XCTAssertEqual(expectedNotes, actualNotes)

        recordIndex = 1
        localGlobalIndex = 7
        let expectedWorkTypes = records.workTypes.map { w in
            w.copy {
                $0.id = recordIndex
                recordIndex += 1
                $0.worksiteId = 1
            }
        }
        let actualWorkTypes = try dbQueue!.selectWorksiteWorkTypes(worksiteId)
        XCTAssertEqual(expectedWorkTypes, actualWorkTypes)

        let actualChanges = try dbQueue!.selectWorksiteChanges(worksiteId)
        let expectedWorksiteChange = WorksiteChangeRecord(
            id: 1,
            appVersion: 81,
            organizationId: 385,
            worksiteId: worksiteId,
            syncUuid: "uuid-7",
            changeModelVersion: 2,
            changeData: "serialized-new-worksite-changes",
            createdAt: actualChanges.first!.createdAt
        )
        XCTAssertEqual([expectedWorksiteChange], actualChanges)
        XCTAssertNearNow(actualChanges.first!.createdAt)
    }

    private func editWorksiteRecords(_ worksiteId: Int64) async throws -> EditWorksiteRecords {
        let dbQueue = dbQueue!
        let savedWorksite = try dbQueue.selectWorksite(worksiteId)
        let flags = try dbQueue.selectWorksiteFlags(worksiteId)
        let formData = try dbQueue.selectWorksiteFormData(worksiteId)
        let notes = try dbQueue.selectWorksiteNotes(worksiteId)
        let workTypes = try dbQueue.selectWorksiteWorkTypes(worksiteId)

        return EditWorksiteRecords(
            core: savedWorksite!,
            flags: flags,
            formData: formData,
            notes: notes,
            workTypes: workTypes
        )
    }

    private func insertRecords(
        _ records: EditWorksiteRecords,
        additionalOperations: @escaping (Database) throws -> Void = {_ in},
        worksiteLocalGlobalUuid: String = ""
    ) async throws -> EditWorksiteRecords {
        let core = records.core
        try await dbQueue!.write { db in
            _ = try WorksiteRootRecord(
                id: core.id,
                syncUuid: "sync-uuid",
                localModifiedAt: core.updatedAt,
                syncedAt: core.updatedAt,
                localGlobalUuid: worksiteLocalGlobalUuid,
                isLocalModified: false,
                syncAttempt: 0,
                networkId: core.networkId,
                incidentId: core.incidentId
            ).insertAndFetch(db)
            _ = try core.insertAndFetch(db)

            for record in records.flags {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }
            for record in records.formData {
                var record = record
                try record.upsert(db)
            }
            for record in records.notes {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }
            for record in records.workTypes {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }

            try additionalOperations(db)
        }

        return try await editWorksiteRecords(records.core.id!)
    }

    /**
     * Establishes initial conditions for [editSyncedWorksite]
     *
     * Maps flags
     * - 1 to 201
     * - 11 to 211, reason-c
     * - 21 to 221
     *
     * Notes
     * - 64 to 264
     * - 41 to 241, note-e, atB
     *
     * Work types
     * - 1 to 301
     * - 23 to 223
     * - 37 to 237
     */
    private func editSyncedWorksite_initialConditions(
        _ worksite: Worksite,
        worksiteLocalGlobalUuid: String = ""
    ) async throws -> EditWorksiteRecords {
        let records = worksite.asRecords(
            uuidGenerator,
            worksite.workTypes[0],
            flagIdLookup: [:],
            noteIdLookup: [:],
            workTypeIdLookup: [:]
        )
        let worksiteId = worksite.id
        return try await insertRecords(
            records,
            additionalOperations: { db in
                // For mapping
                try db.updateWorksiteFlagNetworkId(1, 201)
                _ = try WorksiteFlagRecord(
                    11,
                    211,
                    worksiteId,
                    "",
                    self.createdAtB,
                    false,
                    "",
                    "reason-c",
                    ""
                ).insertAndFetch(db, onConflict: .ignore)
                try db.updateWorksiteFlagNetworkId(21, 221)

                try db.updateWorksiteNoteNetworkId(64, 264)
                _ = try WorksiteNoteRecord(
                    41,
                    "",
                    241,
                    worksiteId,
                    self.createdAtB,
                    false,
                    "note-e"
                ).insertAndFetch(db, onConflict: .ignore)

                try db.updateWorkTypeNetworkId(1, 301)
                _ = try WorkTypeRecord(
                        id: 23,
                        networkId: 223,
                        worksiteId: worksiteId,
                        createdAt: self.createdAtC,
                        orgClaim: 523,
                        nextRecurAt: nil,
                        phase: 2,
                        recur: nil,
                        status: "status-existing",
                        workType: "work-type-existing"
                ).insertAndFetch(db, onConflict: .ignore)
                try db.updateWorkTypeNetworkId(37, 237)
            }
        )
    }

    func testEditSyncedWorksite() async throws {
        let worksiteFull = makeFullWorksite()
        let worksiteSynced = worksiteFull.copy {
            $0.networkId = 515
            if var flags = worksiteFull.flags {
                flags.append(
                    // Is mapped to 221 in initialConditions
                    testWorksiteFlag(
                        21,
                        createdAtB,
                        "reason-network-synced-local-deleted",
                        isHighPriority: true
                    )
                )
                $0.flags = flags
            }
            var workTypes = worksiteFull.workTypes
            workTypes.append(
                testWorkType(
                    37,
                    createdAtB,
                    128,
                    "status-network-synced-local-deleted",
                    "work-type-c"
                )
            )
            $0.workTypes = workTypes
        }

        /*
         * Flags
         * 1 to 201, reason-a
         * 33, reason-b
         * 11 to 211, reason-c
         * 21 to 221, reason-network-synced-local-deleted
         *
         * Notes
         * 1 to -1
         * 41 to 241
         * 64 to 264
         *
         * Work types
         * 1 to 301
         * 23 to 223
         * 37 to 327
         * 57 to -1
         */
        let initialRecords = try await editSyncedWorksite_initialConditions(worksiteSynced)

        let worksiteChanged = changeFullWorksite()
        let worksiteModified = worksiteChanged.copy { $0.networkId = worksiteSynced.networkId }

        changeSerializer.mockClosure(
            true,
            worksiteSynced,
            worksiteModified.copy { copy in
                copy.flags = worksiteModified.flags!.map { f in
                    f.id == 0 ? f.copy { $0.id = 34 } : f
                }
                copy.notes = worksiteModified.notes.enumerated().map { (index, note) in
                    note.id == 0 ? note.copy { $0.id = Int64(index + 63) } : note
                }
                copy.workTypes = worksiteModified.workTypes.map { w in
                    w.id == 0 ? w.copy { $0.id = 58 } : w
                }
            },
            [
                1: 201,
                11: 211,
                21: 221,
            ],
            [
                41: 241,
                64: 264,
            ],
            [
                1: 301,
                23: 223,
                37: 237,
            ],
            mockReturn: (3, "serialized-edit-worksite-changes")
        )

        let primaryWorkType = worksiteModified.workTypes[0]

        let records = worksiteModified.asRecords(
            uuidGenerator,
            primaryWorkType,
            flagIdLookup: [:],
            noteIdLookup: [:],
            workTypeIdLookup: [:]
        )

        _ = try await worksiteChangeDao!.saveChange(
            worksiteStart: worksiteSynced,
            worksiteChange: worksiteModified,
            primaryWorkType: primaryWorkType,
            organizationId: 385,
            localModifiedAt: now
        )

        let worksiteRecord = records.core
        let worksiteId = worksiteRecord.id!

        let actualRoot = try dbQueue!.selectWorksiteRoot(worksiteId)
        let expectedRoot = WorksiteRootRecord(
            id: 56,
            syncUuid: "uuid-11",
            localModifiedAt: now,
            syncedAt: worksiteSynced.updatedAt!,
            localGlobalUuid: "",
            isLocalModified: true,
            syncAttempt: 0,
            networkId: 515,
            incidentId: testIncidentId
        )
        XCTAssertEqual(expectedRoot, actualRoot)

        let actualWorksite = try dbQueue!.selectWorksite(worksiteId)
        XCTAssertEqual(worksiteRecord, actualWorksite)

        func expectedFlagRecord(
            _ id: Int64,
            _ networkId: Int64,
            _ reasonT: String,
            createdAt: Date = createdAtB
        ) -> WorksiteFlagRecord {
            testFlagRecord(
                networkId,
                56,
                createdAt,
                reasonT,
                action: "",
                isHighPriority: false,
                notes: "",
                requestedAction: "",
                id: id
            )
        }

        let expectedFlags = [
            expectedFlagRecord(1, 201, "reason-a", createdAt: createdAtC),
            expectedFlagRecord(11, 211, "reason-c"),
            expectedFlagRecord(34, -1, "reason-d"),
        ]
        let actualFlags = try dbQueue!.selectWorksiteFlags(worksiteId)
            .sorted(by: { a, b in a.id! < b.id! })
        XCTAssertEqual(expectedFlags, actualFlags)

        var expectedFormData = initialRecords.formData
        with(expectedFormData) { formData in
            var notDeleted = formData.filter { $0.fieldKey != "form-data-bt" }

            if let updateIndex = notDeleted.firstIndex(where: { $0.fieldKey == "form-data-sa" }) {
                notDeleted[updateIndex] = notDeleted[updateIndex].copy { $0.valueString = "form-data-value-change-a" }
            }

            records.formData.forEach { record in
                if notDeleted.first(where: { $0.fieldKey == record.fieldKey }) == nil {
                    notDeleted.append(record)
                }
            }

            expectedFormData = notDeleted
        }
        expectedFormData = expectedFormData.sorted(by: { a, b in
            a.fieldKey.localizedCompare(b.fieldKey) == .orderedAscending
        })
        .map { f in f.copy { $0.worksiteId = 56 } }
        let actualFormData = try dbQueue!.selectWorksiteFormData(worksiteId)
            .sorted(by: { a, b in
                a.fieldKey.localizedCompare(b.fieldKey) == .orderedAscending
            })
        expectedFormData = expectedFormData.map { f in
            f.id == nil
            ? f.copy {
                $0.id = actualFormData.first(where: { $0.fieldKey == f.fieldKey })?.id
            }
            : f
        }
        XCTAssertEqual(expectedFormData, actualFormData)

        func expectedNote(
            _ id: Int64,
            _ networkId: Int64,
            _ note: String,
            _ createdAt: Date = createdAtB,
            _ localGlobalUuid: String = ""
        ) -> WorksiteNoteRecord {
            testNotesRecord(
                networkId,
                56,
                createdAt,
                note,
                id: id,
                localGlobalUuid: localGlobalUuid
            )
        }

        let expectedNotes = [
            expectedNote(1, -1, "note-a", createdAtA, "uuid-1"),
            expectedNote(41, 241, "note-e", createdAtB),
            expectedNote(64, 264, "note-b", createdAtB),
            expectedNote(65, -1, "note-c", createdAtC, "uuid-9"),
            expectedNote(66, -1, "note-d", createdAtC, "uuid-10"),
        ]
        let actualNotes = try dbQueue!.selectWorksiteNotes(worksiteId)
            .sorted(by: { a, b in a.id! < b.id! })
        XCTAssertEqual(expectedNotes, actualNotes)

        func expectedWorkType(
            _ id: Int64,
            _ networkId: Int64,
            _ workType: String,
            _ status: String,
            _ orgClaim: Int64? = 523,
            createdAt: Date? = createdAtC,
            phase: Int? = 2,
            nextRecurAt: Date? = nil,
            recur: String? = nil
        ) -> WorkTypeRecord {
            testWorkTypeRecord(
                networkId,
                status: status,
                workType: workType,
                orgClaim: orgClaim,
                worksiteId: 56,
                createdAt: createdAt,
                nextRecurAt: nextRecurAt,
                phase: phase,
                recur: recur,
                id: id
            )
        }

        let expectedWorkTypes = [
            expectedWorkType(1, 301, "work-type-a", "status-a-change", nil, createdAt: createdAtA),
            expectedWorkType(58, -1, "work-type-d", "status-d"),
        ]
        let actualWorkTypes = try dbQueue!.selectWorksiteWorkTypes(worksiteId)
            .sorted(by: { a, b in a.id! < b.id! })
        XCTAssertEqual(expectedWorkTypes, actualWorkTypes)

        let actualChanges = try dbQueue!.selectWorksiteChanges(worksiteId)
        let expectedWorksiteChange = WorksiteChangeRecord(
            id: 1,
            appVersion: 81,
            organizationId: 385,
            worksiteId: worksiteId,
            syncUuid: "uuid-12",
            changeModelVersion: 3,
            changeData: "serialized-edit-worksite-changes",
            createdAt: actualChanges.first!.createdAt
        )
        XCTAssertEqual([expectedWorksiteChange], actualChanges)
        XCTAssertNearNow(actualChanges.first!.createdAt)
    }

    /**
     * Establishes initial conditions for [editSyncedWorksite_deleteExistingFlags]
     */
    private func editSyncedWorksite_deleteExistingFlags_initialConditions(
        _ worksite: Worksite,
        worksiteLocalGlobalUuid: String = ""
    ) async throws -> EditWorksiteRecords {
        let records = worksite.asRecords(
            uuidGenerator,
            worksite.workTypes[0],
            flagIdLookup: [:],
            noteIdLookup: [:],
            workTypeIdLookup: [:]
        )

        return try await insertRecords(
            records,
            additionalOperations: { db in
                try db.updateWorksiteFlagNetworkId(1, 201)
                try db.updateWorksiteFlagNetworkId(21, 221)
            }
        )
    }

    func testEditSyncedWorksite_deleteExistingFlags() async throws {
        let worksiteFull = makeFullWorksite()
        let worksiteSynced = worksiteFull.copy {
            $0.networkId = 515
            if var flags = worksiteFull.flags {
                flags.append(
                    testWorksiteFlag(
                        21,
                        createdAtB,
                        "reason-network-synced-local-deleted",
                        isHighPriority: true
                    )
                )
                $0.flags = flags
            }
        }
        let initialRecords =
        try await editSyncedWorksite_deleteExistingFlags_initialConditions(worksiteSynced)

        let worksiteChanged = changeFullWorksite()

        // Delete all flags. Keep everything else the same.
        let worksiteModified = worksiteChanged.copy {
            $0.networkId = worksiteSynced.networkId
            $0.flags = []
            $0.formData = worksiteSynced.formData
            $0.notes = worksiteSynced.notes.enumerated().map { (index, note) in
                note.id == 0 ? note.copy { $0.id = Int64(index + 1) } : note
            }
            $0.workTypes = worksiteSynced.workTypes.map { w in
                w.id == 0 ? w.copy { $0.id = 1 } : w
            }
        }

        changeSerializer.mockClosure(
            true,
            worksiteSynced,
            worksiteModified,
            [
                1: 201,
                21: 221,
            ],
            [:],
            [:],
            mockReturn: (3, "serialized-edit-worksite-changes")
        )

        let primaryWorkType = worksiteModified.workTypes[0]

        let records = worksiteModified.asRecords(
            uuidGenerator,
            primaryWorkType,
            flagIdLookup: [:],
            noteIdLookup: [:],
            workTypeIdLookup: [:]
        )

        _ = try await worksiteChangeDao!.saveChange(
            worksiteStart: worksiteSynced,
            worksiteChange: worksiteModified,
            primaryWorkType: primaryWorkType,
            organizationId: 385,
            localModifiedAt: now
        )

        let worksiteRecord = records.core
        let worksiteId = worksiteRecord.id!

        let actualRoot = try dbQueue!.selectWorksiteRoot(worksiteId)
        let expectedRoot = WorksiteRootRecord(
            id: 56,
            syncUuid: "uuid-7",
            localModifiedAt: now,
            syncedAt: worksiteSynced.updatedAt!,
            localGlobalUuid: "",
            isLocalModified: true,
            syncAttempt: 0,
            networkId: 515,
            incidentId: testIncidentId
        )
        XCTAssertEqual(expectedRoot, actualRoot)

        let actualWorksite = try dbQueue!.selectWorksite(worksiteId)
        XCTAssertEqual(worksiteRecord, actualWorksite)

        let actualFlags = try dbQueue!.selectWorksiteFlags(worksiteId)
        XCTAssertEqual([WorksiteFlagRecord](), actualFlags)

        let expectedFormData = initialRecords.formData
            .map { f in f.copy { $0.worksiteId = 56 } }
        let actualFormData = try dbQueue!.selectWorksiteFormData(worksiteId)
        XCTAssertEqual(expectedFormData, actualFormData)

        let expectedNotes = initialRecords.notes
        let actualNotes = try dbQueue!.selectWorksiteNotes(worksiteId)
        XCTAssertEqual(expectedNotes, actualNotes)

        let expectedWorkTypes = initialRecords.workTypes
            .map { w in w.copy { $0.worksiteId = 56 } }
            .sorted { a, b in a.id! < b.id! }
        let actualWorkTypes = try dbQueue!.selectWorksiteWorkTypes(worksiteId)
            .sorted { a, b in a.id! < b.id! }
        XCTAssertEqual(expectedWorkTypes, actualWorkTypes)

        let actualChanges = try dbQueue!.selectWorksiteChanges(worksiteId)
        let expectedWorksiteChange = WorksiteChangeRecord(
            id: 1,
            appVersion: 81,
            organizationId: 385,
            worksiteId: worksiteId,
            syncUuid: "uuid-8",
            changeModelVersion: 3,
            changeData: "serialized-edit-worksite-changes",
            createdAt: actualChanges.first!.createdAt
        )
        XCTAssertEqual([expectedWorksiteChange], actualChanges)
        XCTAssertNearNow(actualChanges.first!.createdAt)
    }

    // TODO: Edit unsynced worksite
}

private func testWorksiteFlag(
    _ id: Int64,
    _ createdAt: Date,
    _ reasonT: String,
    isHighPriority: Bool = false
) -> WorksiteFlag {
    WorksiteFlag(
        id: id,
        action: "",
        createdAt: createdAt,
        isHighPriority: isHighPriority,
        notes: "",
        reasonT: reasonT,
        reason: "",
        requestedAction: ""
    )
}

private func testWorksiteNote(
    _ id: Int64,
    _ createdAt: Date,
    _ note: String
) -> WorksiteNote {
    WorksiteNote(
        id: id,
        createdAt: createdAt,
        isSurvivor: false,
        note: note
    )
}

internal func testWorkType(
    _ id: Int64,
    _ createdAt: Date,
    _ orgClaim: Int64?,
    _ status: String,
    _ workType: String,
    phase: Int = 2,
    recur: String? = nil
) -> WorkType {
    WorkType(
        id: id,
        createdAt: createdAt,
        orgClaim: orgClaim,
        nextRecurAt: nil,
        phase: phase,
        recur: recur,
        statusLiteral: status,
        workTypeLiteral: workType
    )
}

extension DerivableRequest<WorksiteFlagRecord> {
    func byWorksiteId(_ worksiteId: Int64) -> Self {
        select(WorksiteFlagRecord.Columns.worksiteId == worksiteId)
    }
}

extension DerivableRequest<WorksiteFormDataRecord> {
    func byWorksiteId(_ worksiteId: Int64) -> Self {
        select(WorksiteFormDataRecord.Columns.worksiteId == worksiteId)
    }
}

extension DatabaseQueue {
    internal func selectWorksiteFlags(_ worksiteId: Int64) throws -> [WorksiteFlagRecord] {
        try read { db in
            try WorksiteFlagRecord
                .filter(WorksiteFlagRecord.Columns.worksiteId == worksiteId)
                .fetchAll(db)
        }
    }

    internal func selectWorksiteFormData(_ worksiteId: Int64) throws -> [WorksiteFormDataRecord] {
        try read { db in
            try WorksiteFormDataRecord
                .filter(WorksiteFormDataRecord.Columns.worksiteId == worksiteId)
                .order(WorksiteFormDataRecord.Columns.id.asc)
                .fetchAll(db)
        }
    }

    internal func selectWorksiteNotes(_ worksiteId: Int64) throws -> [WorksiteNoteRecord] {
        try read { db in
            try WorksiteNoteRecord
                .filter(WorksiteNoteRecord.Columns.worksiteId == worksiteId)
                .fetchAll(db)
        }
    }

    internal func selectWorksiteWorkTypes(_ worksiteId: Int64) throws -> [WorkTypeRecord] {
        try read { db in
            try WorkTypeRecord
                .filter(WorkTypeRecord.Columns.worksiteId == worksiteId)
                .fetchAll(db)
        }
    }

    internal func selectWorksiteRoot(_ worksiteId: Int64) throws -> WorksiteRootRecord? {
        try read { db in
            try WorksiteRootRecord
                .filter(id: worksiteId)
                .fetchOne(db)
        }
    }

    internal func selectWorksite(_ worksiteId: Int64) throws -> WorksiteRecord? {
        try read { db in
            try WorksiteRecord
                .filter(id: worksiteId)
                .fetchOne(db)
        }
    }

    internal func selectWorksiteChanges(_ worksiteId: Int64) throws -> [WorksiteChangeRecord] {
        try read { db in
            try WorksiteChangeRecord
                .filter(WorksiteChangeRecord.Columns.worksiteId == worksiteId)
                .fetchAll(db)
        }
    }
}

extension Database {
    private func updateNetworkId(
        _ tableName: String,
        _ id: Int64,
        _ networkId: Int64
    ) throws {
        try execute(
            sql:
                """
                UPDATE \(tableName)
                SET networkId = :networkId
                WHERE id = :id
                """,
            arguments: [
                "tableName": tableName,
                "id": id,
                "networkId": networkId,
            ]
        )
    }

    internal func updateWorksiteFlagNetworkId(
        _ id: Int64,
        _ networkId: Int64
    ) throws {
        try updateNetworkId("worksiteFlag", id, networkId)
    }

    internal func updateWorksiteNoteNetworkId(
        _ id: Int64,
        _ networkId: Int64
    ) throws {
        try updateNetworkId("worksiteNote", id, networkId)
        if networkId > 0 {
            try execute(
                sql: "UPDATE worksiteNote SET localGlobalUuid = '' WHERE id=:id",
                arguments: ["id": id]
            )
        }
    }

    internal func updateWorkTypeNetworkId(
        _ id: Int64,
        _ networkId: Int64
    ) throws {
        try updateNetworkId("workType", id, networkId)
    }
}

extension WorksiteChangeSerializerMock {
    func mockClosure(
        _ isDataChangedExpected: Bool,
        _ worksiteStartExpected: Worksite,
        _ worksiteChangeExpected: Worksite,
        _ flagIdLookupExpected: [Int64: Int64]?,
        _ noteIdLookupExpected: [Int64: Int64]?,
        _ workTypeIdLookupExpected: [Int64: Int64]?,
        requestReasonExpected: String? = nil,
        requestWorkTypesExpected: [String]? = nil,
        releaseReasonExpected: String? = nil,
        releaseWorkTypesExpected: [String]? = nil,
        mockReturn: (Int, String)
    ) {
        serializeClosure = { (
            isDataChanged: Bool,
            worksiteStart: Worksite,
            worksiteChange: Worksite,
            flagIdLookup: [Int64: Int64],
            noteIdLookup: [Int64: Int64],
            workTypeIdLookup: [Int64: Int64],
            requestReason: String,
            requestWorkTypes: [String],
            releaseReason: String,
            releaseWorkTypes: [String]
        ) in
            if isDataChanged == isDataChangedExpected,
               worksiteStart == worksiteStartExpected,
               worksiteChange == worksiteChangeExpected,
               flagIdLookupExpected == nil || flagIdLookup == flagIdLookupExpected!,
               noteIdLookupExpected == nil || noteIdLookup == noteIdLookupExpected!,
               workTypeIdLookupExpected == nil || workTypeIdLookup == workTypeIdLookupExpected!,
               requestReasonExpected == nil || requestReason == requestReasonExpected!,
               requestWorkTypesExpected == nil || requestWorkTypes == requestWorkTypesExpected!,
               releaseReasonExpected == nil || releaseReason == releaseReasonExpected!,
               releaseWorkTypesExpected == nil || releaseWorkTypes == releaseWorkTypesExpected!
            {
                return mockReturn
            }

            print("Unexpected invocation of serializer start \(worksiteStart==worksiteStartExpected) change \(worksiteChange==worksiteChangeExpected) flag \(flagIdLookup==flagIdLookupExpected) note \(noteIdLookup==noteIdLookupExpected) work type \(workTypeIdLookup==workTypeIdLookupExpected)")
            throw GenericError("Unxpected invocation of serializer")
        }
    }
}
