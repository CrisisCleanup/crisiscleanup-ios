import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteSyncFillTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)

    private var previousSyncedAt: Date = Date.now
    private var createdAtA: Date = Date.now
    private var updatedAtA: Date = Date.now
    private var updatedAtB: Date = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!

    override func setUp() async throws {
        previousSyncedAt = now.addingTimeInterval(-999_999.0.seconds)
        createdAtA = previousSyncedAt.addingTimeInterval(-4_523.0.seconds)
        updatedAtA = createdAtA.addingTimeInterval(15_531.seconds)
        updatedAtB = updatedAtA.addingTimeInterval(75_642.seconds)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        worksiteDao = WorksiteDao(appDb, WorksiteTestUtil.silentSyncLogger)

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }

        }
        let worksite = testWorksiteRecord(1, 1, "address", updatedAtA)
        _ = try await WorksiteTestUtil.insertWorksites(dbQueue, now, [worksite])
    }

    func testSyncFillWorksite() async throws {
        let incidentId = WorksiteTestUtil.testIncidents[0].id
        let rootA = testWorksiteRootRecord(25, incidentId)
        let rootB = testWorksiteRootRecord(26, incidentId)
        let rootD = testWorksiteRootRecord(27, incidentId)
        try await dbQueue.write({ db in
            for record in [rootA, rootB, rootD] {
                var record = record
                try record.insert(db)
            }
        })

        let coreA = testWorksiteFullRecord(rootA.networkId, incidentId, now, id: rootA.id!).copy { $0.id = $0.id }
        let coreB = coreA.copy {
            $0.id = rootB.id
            $0.networkId = rootB.networkId
            $0.autoContactFrequencyT = nil
            $0.caseNumber = ""
            $0.email = nil
            $0.favoriteId = nil
            $0.phone1 = nil
            $0.phone2 = nil
            $0.plusCode = nil
            $0.svi = nil
            $0.reportedBy = nil
            $0.what3Words = nil
        }
        let coreD = coreB.copy {
            $0.id = rootD.id
            $0.networkId = rootD.networkId
            $0.caseNumber = coreA.caseNumber
            $0.phone1 = "0"
        }
        try await dbQueue.write({ db in
            for record in [coreA, coreB, coreD] {
                var record = record
                try record.insert(db)
            }
        })

        try await dbQueue.write { db in
            for flag in [
                self.testWorksiteFlagRecord("reason-a", rootA.id!, 34),
                self.testWorksiteFlagRecord("reason-b", rootB.id!, 35),
                self.testWorksiteFlagRecord("reason-c", rootA.id!, 36),
                self.testWorksiteFlagRecord("reason-d", rootA.id!, 37),
            ] {
                var flag = flag
                try flag.insert(db, onConflict: .ignore)
            }

            for formData in [
                self.testWorksiteFormDataRecord(rootA.id!, "field-a", "value-a"),
                self.testWorksiteFormDataRecord(rootA.id!, "field-b", "value-b"),
                self.testWorksiteFormDataRecord(rootB.id!, "field-c", "value-c"),
            ] {
                var formData = formData
                try formData.upsert(db)
            }

            for note in [
                self.testWorksiteNoteRecord("note-a", rootA.id!, 57, (-1).hours, 13),
                self.testWorksiteNoteRecord("note-b", rootA.id!, 58, 1.hours, 14),
                self.testWorksiteNoteRecord("note-c", rootA.id!, 59, (-1).hours, 15),
                self.testWorksiteNoteRecord("note-d", rootA.id!, 60, 1.hours, 16),
                self.testWorksiteNoteRecord("note-e", rootB.id!, 61, (-1).hours, 17),
                self.testWorksiteNoteRecord("note-f", rootB.id!, 62, 1.hours, 18),
            ] {
                var note = note
                try note.insert(db, onConflict: .ignore)
            }

            for workType in [
                self.testWorkTypeRecord(35, "status-a", "type-a", 25, rootA.id!),
                self.testWorkTypeRecord(36, "status-b", "type-b", 26, rootA.id!),
                self.testWorkTypeRecord(37, "status-c", "type-c", 26, rootA.id!),
                self.testWorkTypeRecord(38, "status-d", "type-d", 25, rootB.id!),
            ] {
                var workType = workType
                try workType.insert(db, onConflict: .ignore)
            }
        }

        let updateCore = coreA.copy {
            $0.incidentId = incidentId
            $0.address = "\($0.address)-update"
            $0.autoContactFrequencyT = "\($0.autoContactFrequencyT!)-update"
            $0.caseNumber = "\($0.caseNumber)-update"
            $0.city = "\($0.city)-update"
            $0.county = "\($0.county)-update"
            $0.createdAt = $0.createdAt!.addingTimeInterval(1.hours)
            $0.email = "\($0.email!)-update"
            $0.favoriteId = 854
            $0.keyWorkTypeType = "\($0.keyWorkTypeType)-update"
            $0.keyWorkTypeOrgClaim = $0.keyWorkTypeOrgClaim
            $0.keyWorkTypeStatus = "\($0.keyWorkTypeStatus)-update"
            $0.latitude = $0.latitude + 0.1
            $0.longitude = $0.longitude + 0.1
            $0.name = "\($0.name)-update"
            $0.phone1 = "\($0.phone1!)-update"
            $0.phone2 = "\($0.phone2!)-update"
            $0.plusCode = "\($0.plusCode!)-update"
            $0.postalCode = "\($0.postalCode)-update"
            $0.reportedBy = 7835
            $0.state = "\($0.state)-update"
            $0.svi = $0.svi! * 2
            $0.what3Words = "\($0.what3Words!)-update"
            $0.updatedAt = $0.updatedAt.addingTimeInterval(99.seconds)
        }
        let recordsA = WorksiteRecords(
            updateCore.copy {
                $0.networkId = coreA.networkId
            },
            [
                testWorksiteFlagRecord(
                    "reason-a",
                    rootA.id!,
                    networkId: 162,
                    action: "action-change"
                ),
                testWorksiteFlagRecord(
                    "reason-b",
                    rootA.id!,
                    networkId: 163,
                    action: "action-change"
                ),
                testWorksiteFlagRecord(
                    "reason-d",
                    rootA.id!,
                    networkId: 81,
                    action: "action-change"
                ),
            ],
            [
                testWorksiteFormDataRecord(rootA.id!, "field-a", "value-a-change"),
                testWorksiteFormDataRecord(rootA.id!, "field-c", "value-c-change"),
            ],
            [
                testWorksiteNoteRecord("note-a", rootA.id!, 77, 9.hours),
                testWorksiteNoteRecord("note-b", rootA.id!, 78, 9.hours),
                testWorksiteNoteRecord("note-c-change", rootA.id!, 59, 9.hours),
                testWorksiteNoteRecord("note-e", rootA.id!, 79, 9.hours),
                testWorksiteNoteRecord("note-f", rootA.id!, 80, 9.hours),
            ],
            [
                testWorkTypeRecord(71, "status-a-change", "type-a", 25, rootA.id!),
                testWorkTypeRecord(72, "status-b-change", "type-b", 26, rootA.id!),
                testWorkTypeRecord(37, "status-c-change", "type-c", 26, rootA.id!),
                testWorkTypeRecord(73, "status-d-change", "type-d", 25, rootA.id!),
            ]
        )

        let recordsB = WorksiteRecords(
            updateCore.copy {
                $0.id = coreB.id
                $0.networkId = coreB.networkId
            },
            [],
            [],
            [],
            []
        )
        let expectedCoreUpdate = coreA.copy {
            $0.id = coreB.id
            $0.networkId = coreB.networkId
            $0.autoContactFrequencyT = updateCore.autoContactFrequencyT
            $0.caseNumber = "case-update"
            $0.email = updateCore.email
            $0.favoriteId = updateCore.favoriteId!
            $0.phone1 = updateCore.phone1
            $0.phone2 = updateCore.phone2
            $0.plusCode = updateCore.plusCode
            $0.svi = updateCore.svi!
            $0.reportedBy = updateCore.reportedBy
            $0.what3Words = updateCore.what3Words
        }

        let recordsD = WorksiteRecords(
            updateCore.copy {
                $0.id = coreD.id
                $0.caseNumber = "c"
                $0.networkId = coreD.networkId
            },
            [],
            [],
            [],
            []
        )
        let expectedCoreD = expectedCoreUpdate.copy {
            $0.id = coreD.id
            $0.caseNumber = coreA.caseNumber
            $0.networkId = coreD.networkId
        }

        let actualA = try await dbQueue.write({ db in
            try self.worksiteDao.syncFillWorksite(db, recordsA)
        })
        XCTAssertTrue(actualA)

        let actualCoreA = try await dbQueue.write({ db in try WorksiteRecord.filter(id: rootA.id!).fetchOne(db) })
        XCTAssertEqual(coreA, actualCoreA)

        let actualB = try await dbQueue.write({ db in
            try self.worksiteDao.syncFillWorksite(db, recordsB)
        })
        XCTAssertTrue(actualB)

        let actualCoreB = try await dbQueue.write({ db in try WorksiteRecord.filter(id: rootB.id!).fetchOne(db) })
        XCTAssertEqual(expectedCoreUpdate, actualCoreB)

        let actualD = try await dbQueue.write({ db in
            try self.worksiteDao.syncFillWorksite(db, recordsD)
        })
        XCTAssertTrue(actualD)

        let actualCoreD = try await dbQueue.write({ db in try WorksiteRecord.filter(id: rootD.id!).fetchOne(db) })
        XCTAssertEqual(expectedCoreD, actualCoreD)

        let expectedFlagsA = [
            testWorksiteFlagRecord("reason-a", rootA.id!, 34),
            testWorksiteFlagRecord("reason-c", rootA.id!, 36),
            testWorksiteFlagRecord("reason-d", rootA.id!, 37),
            testWorksiteFlagRecord(
                "reason-b",
                rootA.id!,
                38,
                networkId: 163,
                action: "action-change"
            ),
        ]

        let actualFlagsA = try await dbQueue.write({ db in try WorksiteFlagRecord.getFlags(db, rootA.id!) })
            .sorted(by: { a, b in a.id! <= b.id! })
        XCTAssertEqual(expectedFlagsA, actualFlagsA)

        let expectedFlagsB = [testWorksiteFlagRecord("reason-b", rootB.id!, 35)]
        let actualFlagsB = try await dbQueue.write({ db in try WorksiteFlagRecord.getFlags(db, rootB.id!) })
        XCTAssertEqual(expectedFlagsB, actualFlagsB)

        let expectedFormDataA = [
            testWorksiteFormDataRecord(rootA.id!, "field-a", "value-a", id: 1),
            testWorksiteFormDataRecord(rootA.id!, "field-b", "value-b", id: 2),
            testWorksiteFormDataRecord(rootA.id!, "field-c", "value-c-change", id: 4),
        ]
        let actualFormDataA = try await dbQueue.write({ db in try WorksiteFormDataRecord.getFormData(db, rootA.id!) })
        XCTAssertEqual(expectedFormDataA, actualFormDataA)

        let actualFormDataB = try await dbQueue.write({ db in try WorksiteFormDataRecord.getFormData(db, rootB.id!) })
        let expectedFormDataB = [
            testWorksiteFormDataRecord(rootB.id!, "field-c", "value-c", id: 3),
        ]
        XCTAssertEqual(expectedFormDataB, actualFormDataB)

        let expectedNotesA = [
            testWorksiteNoteRecord("note-a", rootA.id!, 57, -1.hours, 13),
            testWorksiteNoteRecord("note-b", rootA.id!, 58, 1.hours, 14),
            testWorksiteNoteRecord("note-c", rootA.id!, 59, -1.hours, 15),
            testWorksiteNoteRecord("note-d", rootA.id!, 60, 1.hours, 16),
            testWorksiteNoteRecord("note-a", rootA.id!, 77, 9.hours, 19),
            testWorksiteNoteRecord("note-e", rootA.id!, 79, 9.hours, 21),
            testWorksiteNoteRecord("note-f", rootA.id!, 80, 9.hours, 22),
        ]
        let actualNotesA = try await dbQueue.write({ db in try WorksiteNoteRecord.getNoteRecords(db, rootA.id!) })
            .sorted(by: { a, b in a.id! <= b.id! })
        XCTAssertEqual(expectedNotesA, actualNotesA)

        let expectedNotesB = [
            testWorksiteNoteRecord("note-e", rootB.id!, 61, (-1).hours, 17),
            testWorksiteNoteRecord("note-f", rootB.id!, 62, 1.hours, 18),
        ]
        let actualNotesB = try await dbQueue.write({ db in try WorksiteNoteRecord.getNoteRecords(db, rootB.id!) })
        XCTAssertEqual(expectedNotesB, actualNotesB)

        let expectedWorkTypesA = [
            testWorkTypeRecord(35, "status-a", "type-a", 25, rootA.id!, id: 1),
            testWorkTypeRecord(36, "status-b", "type-b", 26, rootA.id!, id: 2),
            testWorkTypeRecord(37, "status-c", "type-c", 26, rootA.id!, id: 3),
            testWorkTypeRecord(73, "status-d-change", "type-d", 25, rootA.id!, id: 5),
        ]
        let actualWorkTypesA = try await dbQueue.write({ db in try WorkTypeRecord.getWorkTypeRecords(db, rootA.id!) })
        XCTAssertEqual(expectedWorkTypesA, actualWorkTypesA)

        let expectedWorkTypesB = [
            testWorkTypeRecord(38, "status-d", "type-d", 25, rootB.id!, id: 4),
        ]
        let actualWorkTypesB = try await dbQueue.write({ db in try WorkTypeRecord.getWorkTypeRecords(db, rootB.id!) })
        XCTAssertEqual(expectedWorkTypesB, actualWorkTypesB)
    }

    private func testWorksiteRootRecord(
        _ id: Int64,
        _ incidentId: Int64
    ) -> WorksiteRootRecord {
        testWorksiteRootRecord(id, incidentId, id+30)
    }
    private func testWorksiteRootRecord(
        _ id: Int64,
        _ incidentId: Int64,
        _ networkId: Int64
    ) -> WorksiteRootRecord {
        WorksiteRootRecord(
            id: id,
            syncUuid: "",
            localModifiedAt: now,
            syncedAt: epoch0,
            localGlobalUuid: "",
            isLocalModified: true,
            syncAttempt: 0,
            networkId: networkId,
            incidentId: incidentId
        )
    }

    private func testWorksiteFlagRecord(
        _ reasonT: String,
        _ worksiteId: Int64,
        _ id: Int64,
        action: String = ""
    ) -> WorksiteFlagRecord {
        testWorksiteFlagRecord(
            reasonT,
            worksiteId,
            id,
            networkId: id + 44,
            action: action
        )
    }
    private func testWorksiteFlagRecord(
        _ reasonT: String,
        _ worksiteId: Int64,
        _ id: Int64? = nil,
        networkId: Int64,
        action: String = ""
    ) -> WorksiteFlagRecord {
        WorksiteFlagRecord(
            id: id,
            networkId: networkId,
            worksiteId: worksiteId,
            action: action,
            createdAt: now,
            isHighPriority: false,
            notes: "",
            reasonT: reasonT,
            requestedAction: ""
        )
    }

    private func testWorksiteFormDataRecord(
        _ worksiteId: Int64,
        _ fieldKey: String,
        _ fieldValue: String,
        id: Int64? = nil
    ) -> WorksiteFormDataRecord {
        WorksiteFormDataRecord(
            id,
            worksiteId,
            fieldKey,
            false,
            fieldValue,
            false
        )
    }

    private func testWorksiteNoteRecord(
        _ note: String,
        _ worksiteId: Int64,
        _ networkId: Int64,
        _ deltaReferenceTime: TimeInterval,
        _ id: Int64? = nil
    ) -> WorksiteNoteRecord {
        WorksiteNoteRecord(
            id: id,
            localGlobalUuid: "",
            networkId: networkId,
            worksiteId: worksiteId,
            createdAt: now.addingTimeInterval(-12.hours).addingTimeInterval(deltaReferenceTime),
            isSurvivor: false,
            note: note
        )
    }

    private func testWorkTypeRecord(
        _ networkId: Int64,
        _ status: String,
        _ workType: String,
        _ orgClaim: Int64?,
        _ worksiteId: Int64,
        createdAt: Date? = nil,
        nextRecurAt: Date? = nil,
        phase: Int? = nil,
        recur: String? = nil,
        id: Int64? = nil
    ) -> WorkTypeRecord {
        CrisisCleanupTests.testWorkTypeRecord(
            networkId,
            status: status,
            workType: workType,
            orgClaim: orgClaim,
            worksiteId: worksiteId,
            createdAt: createdAt,
            nextRecurAt: nextRecurAt,
            phase: phase,
            recur: recur,
            id: id
        )
    }
}
