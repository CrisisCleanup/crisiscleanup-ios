import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteFormDataFlagNoteTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var previousSyncedAt: Date = Date.now
    private var createdAtA: Date = Date.now
    private var updatedAtA: Date = Date.now
    private var updatedAtB: Date = Date.now

    private var dbQueue: DatabaseQueue? = nil
    private var appDb: AppDatabase? = nil
    private var worksiteDao: WorksiteDao? = nil

    override func setUp() async throws {
        previousSyncedAt = now.addingTimeInterval(-999_999.0.seconds)
        createdAtA = previousSyncedAt.addingTimeInterval(-4_523.0.seconds)
        updatedAtA = createdAtA.addingTimeInterval(15_531.seconds)
        updatedAtB = updatedAtA.addingTimeInterval(75_642.seconds)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        worksiteDao = WorksiteDao(appDb!, WorksiteTestUtil.silentSyncLogger)

        try await dbQueue!.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }
    }

    private func insertWorksites(
        _ worksites: [WorksiteRecord],
        _ syncedAt: Date
    ) async throws -> [WorksiteRecord] {
        try await WorksiteTestUtil.insertWorksites(
            dbQueue!,
            syncedAt,
            worksites
        )
    }

    private let myOrgId = Int64(217)

    func testSyncNewWorksite() async throws {
        let syncingWorksite = testWorksiteRecord(1, 1, "sync-address", updatedAtA)

        let syncingFormData = [
            testFormDataRecord(
                1,
                "form-field-c",
                value: "doesn't matter",
                isBoolValue: true,
                valueBool: false
            ),
        ]
        let syncingFlags = [
            testFullFlagRecord(432, 1, updatedAtB, true, "new-a"),
        ]
        let syncingNotes = [
            testNotesRecord(34, 1, updatedAtB, "note-new-a", isSurvivor: true),
            testNotesRecord(45, 1, updatedAtA, "note-new-b"),
        ]
        // Sync existing
        let syncedAt = previousSyncedAt.addingTimeInterval(499_999.seconds)
        let records = WorksiteRecords(
            syncingWorksite,
            syncingFlags,
            syncingFormData,
            syncingNotes,
            []
        )
        let actual = try await dbQueue!.write({ db in
            try self.worksiteDao!.syncWorksite(db, records, syncedAt)
        })
        XCTAssertEqual(true, actual.0)
        XCTAssertEqual(1, actual.1)

        // Assert

        let actualPopulatedWorksite = try worksiteDao!.getLocalWorksite(1)
        XCTAssertEqual(
            testWorksiteRecord(1, 1, "sync-address", updatedAtA, id: 1),
            actualPopulatedWorksite?.worksite
        )

        let expectedFormDataRecords = [
            WorksiteFormDataRecord(
                1, 1, "form-field-c", true, "doesn't matter", false
            ),
        ]
        XCTAssertEqual(expectedFormDataRecords, actualPopulatedWorksite!.worksiteFormData)

        let expectedFlagRecords = [
            WorksiteFlagRecord(
                1,
                432,
                1,
                "action-new-a",
                updatedAtB,
                true,
                "notes-new-a",
                "reason-new-a",
                "requested-action-new-a"
            ),
        ]
        XCTAssertEqual(expectedFlagRecords, actualPopulatedWorksite!.worksiteFlags)

        let expectedNoteRecords = [
            WorksiteNoteRecord(
                2, "", 45, 1, updatedAtA, false, "note-new-b"
            ),
            WorksiteNoteRecord(
                1, "", 34, 1, updatedAtB, true, "note-new-a"
            ),
        ]
        XCTAssertEqual(expectedNoteRecords, actualPopulatedWorksite!.worksiteNotes)

        let actualWorksite =
        actualPopulatedWorksite!.asExternalModel(myOrgId, WorksiteTestUtil.testTranslator)

        let expectedFormData = [
            "form-field-c": WorksiteFormValue(
                isBoolean: true,
                valueString: "doesn't matter",
                valueBoolean: false
            ),
        ]
        XCTAssertEqual(expectedFormData, actualWorksite.worksite.formData)

        let expectedFlags = [
            WorksiteFlag(
                id: 1,
                action: "action-new-a",
                createdAt: updatedAtB,
                isHighPriority: true,
                notes: "notes-new-a",
                reasonT: "reason-new-a",
                reason: "reason-new-a-translated",
                requestedAction: "requested-action-new-a"
            ),
        ]
        XCTAssertEqual(expectedFlags, actualWorksite.worksite.flags)

        let expectedNotes = [
            WorksiteNote(2, updatedAtA, false, "note-new-b"),
            WorksiteNote(1, updatedAtB, true, "note-new-a"),
        ]
        XCTAssertEqual(expectedNotes, actualWorksite.worksite.notes)
    }

    /**
     * Syncing form data, flags, and notes overwrite local (where unchanged)
     */
    func testSyncExistingWorksite() async throws {
        // Insert existing
        var existingWorksites = [
            testWorksiteRecord(1, 1, "address", updatedAtA),
        ]
        existingWorksites = try await insertWorksites(existingWorksites, previousSyncedAt)

        try await dbQueue!.write({ db in
            for formData in [
                testFormDataRecord(1, "form-field-a"),
                testFormDataRecord(1, "form-field-b"),
                testFormDataRecord(1, "form-field-c", isBoolValue: true, valueBool: true),
            ] {
                var formData = formData
                try formData.upsert(db)
            }

            for flag in [
                testFlagRecord(11, 1, self.createdAtA, "flag-a"),
                testFlagRecord(12, 1, self.createdAtA, "flag-b"),
            ] {
                var flag = flag
                try flag.insert(db, onConflict: .ignore)
            }

            for note in [
                testNotesRecord(21, 1, self.createdAtA, "note-a"),
                testNotesRecord(22, 1, self.createdAtA, "note-b"),
            ] {
                var note = note
                try note.insert(db, onConflict: .ignore)
            }
        })

        // Sync
        let syncingWorksite = testWorksiteRecord(1, 1, "sync-address", updatedAtB)
        let syncingFormData = [
            // Update
            testFormDataRecord(1, "form-field-b", value: "updated-value"),
            testFormDataRecord(
                1,
                "form-field-c",
                value: "doesn't matter",
                isBoolValue: true,
                valueBool: false
            ),
            // Delete form-field-a
            // New
            testFormDataRecord(1, "form-field-new-a", value: "value-new"),
        ]
        let syncingFlags = [
            // New
            testFullFlagRecord(432, 1, updatedAtA, false, "new-a"),
            // Delete 11
            // Update
            testFlagRecord(
                12,
                1,
                updatedAtA,
                "flag-b",
                action: "updated-flag-b",
                isHighPriority: true,
                notes: "updated-notes-flag-b",
                requestedAction: "updated-requested-action-flag-b"
            ),
        ]
        let syncingNotes = [
            // Update
            testNotesRecord(21, 1, updatedAtA, "note-update-a", isSurvivor: true),
            // New
            testNotesRecord(34, 1, updatedAtA, "note-new-a", isSurvivor: true),
            testNotesRecord(45, 1, updatedAtA, "note-new-b"),
            // Delete 22
        ]
        // Sync existing
        let syncedAt = previousSyncedAt.addingTimeInterval(499_999.seconds)
        let records = WorksiteRecords(
            syncingWorksite,
            syncingFlags,
            syncingFormData,
            syncingNotes,
            []
        )
        let expectedSyncedWorksiteId = existingWorksites[0].id
        let actual = try await dbQueue!.write({ db in
            try self.worksiteDao!.syncWorksite(db, records, syncedAt)
        })
        XCTAssertEqual(true, actual.0)
        XCTAssertEqual(expectedSyncedWorksiteId, actual.1)

        let actualPopulatedWorksite = try worksiteDao!.getLocalWorksite(1)!
        XCTAssertEqual(
            existingWorksites[0].copy {
                $0.address = "sync-address"
                $0.updatedAt = updatedAtB
            },
            actualPopulatedWorksite.worksite
        )

        let actualWorksite =
            actualPopulatedWorksite.asExternalModel(myOrgId, WorksiteTestUtil.testTranslator)

        let expectedFormData = [
            "form-field-b": WorksiteFormValue(
                isBoolean: false,
                valueString: "updated-value",
                valueBoolean: false
            ),
            "form-field-c": WorksiteFormValue(
                isBoolean: true,
                valueString: "doesn't matter",
                valueBoolean: false
            ),
            "form-field-new-a": WorksiteFormValue(
                isBoolean: false,
                valueString: "value-new",
                valueBoolean: false
            ),
        ]
        XCTAssertEqual(expectedFormData, actualWorksite.worksite.formData)

        let expectedFlags = [
            WorksiteFlag(
                id: 2,
                action: "updated-flag-b",
                createdAt: updatedAtA,
                isHighPriority: true,
                notes: "updated-notes-flag-b",
                reasonT: "flag-b",
                reason: "flag-b-translated",
                requestedAction: "updated-requested-action-flag-b"
            ),
            WorksiteFlag(
                id: 3,
                action: "action-new-a",
                createdAt: updatedAtA,
                isHighPriority: false,
                notes: "notes-new-a",
                reasonT: "reason-new-a",
                reason: "reason-new-a-translated",
                requestedAction: "requested-action-new-a"
            ),
        ]
        XCTAssertEqual(expectedFlags, actualWorksite.worksite.flags)

        let expectedNotes = [
            WorksiteNote(5, updatedAtA, false, "note-new-b"),
            WorksiteNote(4, updatedAtA, true, "note-new-a"),
            WorksiteNote(1, updatedAtA, true, "note-update-a"),
        ]
        XCTAssertEqual(expectedNotes, actualWorksite.worksite.notes)
    }

    func testSyncSkipLocallyModified() async throws {
        // Insert existing
        var existingWorksites = [
            testWorksiteRecord(1, 1, "address", updatedAtA),
            testWorksiteRecord(2, 1, "address", updatedAtA),
        ]
        existingWorksites = try await insertWorksites(existingWorksites, previousSyncedAt)
        try await WorksiteTestUtil.setModifiedAt(dbQueue!, 2, updatedAtA)

        // Sync

        let syncingWorksite = testWorksiteRecord(1, 1, "sync-address", updatedAtB)
        let syncingFormData = [
            testFormDataRecord(
                1, "form-field-a",
                value: "doesn't-matter",
                isBoolValue: true,
                valueBool: false
            ),
        ]
        let syncingFlags = [
            testFullFlagRecord(432, 1, updatedAtA, false, "flag-a"),
        ]
        let syncingNotes = [
            testNotesRecord(34, 1, updatedAtA, "note-a", isSurvivor: true),
        ]

        // Sync locally unchanged
        let syncedAt = previousSyncedAt.addingTimeInterval(499_999.seconds)
        let records = WorksiteRecords(
            syncingWorksite,
            syncingFlags,
            syncingFormData,
            syncingNotes,
            []
        )
        let actualSyncWorksite = try await dbQueue!.write({ db in
            try self.worksiteDao!.syncWorksite(db, records, syncedAt)
        })

        // Sync locally changed
        let syncingWorksiteB = testWorksiteRecord(2, 1, "sync-address", updatedAtB)
        let syncingFormDataB = [
            testFormDataRecord(2, "form-field-b", value: "updated-value"),
        ]
        let syncingFlagsB = [
            testFullFlagRecord(12, 2, updatedAtA, true, "flag-b"),
        ]
        let syncingNotesB = [
            testNotesRecord(45, 2, updatedAtA, "note-b"),
        ]
        // Sync existing
        let recordsB = WorksiteRecords(
            syncingWorksiteB,
            syncingFlagsB,
            syncingFormDataB,
            syncingNotesB,
            []
        )
        let actualSyncChangeWorksite = try await dbQueue!.write({ db in
            try self.worksiteDao!.syncWorksite(db, recordsB, syncedAt)
        })

        // Assert

        XCTAssertEqual(true, actualSyncWorksite.0)
        XCTAssertEqual(existingWorksites[0].id, actualSyncWorksite.1)

        let actualPopulatedWorksite = try worksiteDao!.getLocalWorksite(1)!
        XCTAssertEqual(
            existingWorksites[0].copy {
                $0.address = "sync-address"
                $0.updatedAt = updatedAtB
            },
            actualPopulatedWorksite.worksite
        )

        let actualWorksite =
            actualPopulatedWorksite.asExternalModel(myOrgId, WorksiteTestUtil.testTranslator)

        let expectedFormData = [
            "form-field-a": WorksiteFormValue(
                isBoolean: true,
                valueString: "doesn't-matter",
                valueBoolean: false
            ),
        ]
        XCTAssertEqual(expectedFormData, actualWorksite.worksite.formData)

        let expectedFlags = [
            WorksiteFlag(
                id: 1,
                action: "action-flag-a",
                createdAt: updatedAtA,
                isHighPriority: false,
                notes: "notes-flag-a",
                reasonT: "reason-flag-a",
                reason: "reason-flag-a-translated",
                requestedAction: "requested-action-flag-a"
            ),
        ]
        XCTAssertEqual(expectedFlags, actualWorksite.worksite.flags)

        let expectedNotes = [WorksiteNote(1, updatedAtA, true, "note-a")]
        XCTAssertEqual(expectedNotes, actualWorksite.worksite.notes)

        // Locally changed did not sync

        XCTAssertEqual(false, actualSyncChangeWorksite.0)
        XCTAssertEqual(-1, actualSyncChangeWorksite.1)

        let actualPopulatedWorksiteB = try worksiteDao!.getLocalWorksite(2)!
        XCTAssertEqual(existingWorksites[1], actualPopulatedWorksiteB.worksite)
        let actualWorksiteB =
            actualPopulatedWorksiteB.asExternalModel(myOrgId, WorksiteTestUtil.testTranslator)
        XCTAssertEqual([:], actualWorksiteB.worksite.formData)
        XCTAssertEqual([], actualWorksiteB.worksite.flags)
        XCTAssertEqual([], actualWorksiteB.worksite.notes)
    }
}

internal func testFormDataRecord(
    _ worksiteId: Int64,
    _ key: String,
    value: String = "value",
    isBoolValue: Bool = false,
    valueBool: Bool = false
) ->  WorksiteFormDataRecord {
    WorksiteFormDataRecord(
        id: nil,
        worksiteId: worksiteId,
        fieldKey: key,
        isBoolValue: isBoolValue,
        valueString: value,
        valueBool: valueBool
    )
}

internal func testFlagRecord(
    _ networkId: Int64,
    _ worksiteId: Int64,
    _ createdAt: Date,
    _ reasonT: String,
    action: String? = nil,
    isHighPriority: Bool? = nil,
    notes: String? = nil,
    requestedAction: String? = nil,
    id: Int64? = nil
) -> WorksiteFlagRecord {
    WorksiteFlagRecord(
        id: id,
        networkId: networkId,
        worksiteId: worksiteId,
        action: action,
        createdAt: createdAt,
        isHighPriority: isHighPriority,
        notes: notes,
        reasonT: reasonT,
        requestedAction: requestedAction
    )
}

internal func testFullFlagRecord(
    _ networkId: Int64,
    _ worksiteId: Int64,
    _ createdAt: Date,
    _ isHighPriority: Bool?,
    _ postfix: String,
    id: Int64? = nil
) -> WorksiteFlagRecord {
    testFlagRecord(
        networkId,
        worksiteId,
        createdAt,
        "reason-\(postfix)",
        action: "action-\(postfix)",
        isHighPriority: isHighPriority,
        notes: "notes-\(postfix)",
        requestedAction: "requested-action-\(postfix)",
        id: id
    )
}

internal func testNotesRecord(
    _ networkId: Int64,
    _ worksiteId: Int64,
    _ createdAt: Date,
    _ note: String,
    isSurvivor: Bool = false,
    id: Int64? = nil,
    localGlobalUuid: String = ""
) -> WorksiteNoteRecord {
    WorksiteNoteRecord(
        id: id,
        localGlobalUuid: localGlobalUuid,
        networkId: networkId,
        worksiteId: worksiteId,
        createdAt: createdAt,
        isSurvivor: isSurvivor,
        note: note
    )
}
