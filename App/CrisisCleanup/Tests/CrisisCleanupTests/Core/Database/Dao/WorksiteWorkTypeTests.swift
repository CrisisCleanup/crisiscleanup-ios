import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

/**
 * Sync worksites with work types
 */
class WorksiteWorkTypeTests: XCTestCase {
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

    func testSyncingWorksitesMustHaveWorkTypes() async throws {
        let syncedAt = previousSyncedAt.addingTimeInterval(487.seconds)
        let syncingWorksites = [
            testWorksiteShortRecord(111, 1, createdAtA),
        ]
        do {
            try await worksiteDao!.syncWorksites(syncingWorksites, [], syncedAt)
            XCTFail("Expecting test to error")
        } catch is GenericError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Error type not expected")
        }
    }

    /**
     * Syncing work types overwrites local (where unchanged)
     */
    func testSyncWorksiteWorkTypes() async throws {
        // Insert existing
        var existingWorksites = [
            testWorksiteRecord(1, 1, "address", updatedAtA),
            testWorksiteRecord(2, 1, "address", updatedAtA),
        ]
        existingWorksites = try await insertWorksites(existingWorksites, previousSyncedAt)
        try await dbQueue!.write({ db in
            for workType in [
                testWorkTypeRecord(1, workType: "work-type-a", worksiteId: 1),
                testWorkTypeRecord(11, workType: "work-type-b", worksiteId: 1),
            ] {
                var workType = workType
                try workType.insert(db, onConflict: .ignore)
            }
        })

        // Sync
        let syncingWorksites = [
            testWorksiteRecord(1, 1, "sync-address", updatedAtB),
            testWorksiteRecord(2, 1, "sync-address", updatedAtB),
        ]
        let createdAtC = now.addingTimeInterval(200.seconds)
        let nextRecurAtC = createdAtC.addingTimeInterval(1.days)
        let syncingWorkTypes = [
            [
                // Update
                testWorkTypeRecord(
                    1,
                    status: "status-synced-update",
                    workType: "work-type-a",
                    orgClaim: 5498,
                    worksiteId: 1,
                    createdAt: createdAtC,
                    nextRecurAt: nextRecurAtC,
                    phase: 84,
                    recur: "recur-synced-update"
                ),
                // Delete 11
                // New
                testWorkTypeRecord(15, workType: "work-type-synced-c", worksiteId: 1),
                testWorkTypeRecord(
                    22,
                    status: "status-synced-new",
                    workType: "work-type-synced-d",
                    orgClaim: 8456,
                    worksiteId: 1,
                    createdAt: createdAtC,
                    nextRecurAt: nextRecurAtC,
                    phase: 93,
                    recur: "recur-synced-new"
                ),
            ],
            [
                testWorkTypeRecord(24, workType: "work-type-a", worksiteId: 2),
                testWorkTypeRecord(26, workType: "work-type-b", worksiteId: 2),
            ],
        ]
        // Sync new and existing
        let syncedAt = previousSyncedAt.addingTimeInterval(499_999.seconds)
        try await worksiteDao!.syncWorksites(syncingWorksites, syncingWorkTypes, syncedAt)

        // Assert

        var actual = try worksiteDao!.getWorksite(1)!
        XCTAssertEqual(
            existingWorksites[0].copy {
                $0.address = "sync-address"
                $0.updatedAt = updatedAtB
            },
            actual.worksite
        )
        let expectedWorkTypeRecordsA = [
            testWorkTypeRecord(
                1,
                status: "status-synced-update",
                workType: "work-type-a",
                orgClaim: 5498,
                worksiteId: 1,
                createdAt: createdAtC,
                nextRecurAt: nextRecurAtC,
                phase: 84,
                recur: "recur-synced-update",
                id: 1
            ),
            testWorkTypeRecord(15, worksiteId: 1)
                .copy {
                    $0.id = 4
                    $0.workType = "work-type-synced-c"
                },
            testWorkTypeRecord(
                22,
                status: "status-synced-new",
                workType: "work-type-synced-d",
                orgClaim: 8456,
                worksiteId: 1,
                createdAt: createdAtC,
                nextRecurAt: nextRecurAtC,
                phase: 93,
                recur: "recur-synced-new",
                id: 5
            ),
        ]
        XCTAssertEqual(expectedWorkTypeRecordsA, actual.workTypes.sorted(by: { a, b in
            a.id! - b.id! <= 0
        }))

        let expectedWorkTypes = [
            WorkType(
                id: 1,
                createdAt: createdAtC,
                orgClaim: 5498,
                nextRecurAt: nextRecurAtC,
                phase: 84,
                recur: "recur-synced-update",
                statusLiteral: "status-synced-update",
                workTypeLiteral: "work-type-a"
            ),
            WorkType(
                id: 4,
                createdAt: nil,
                orgClaim: 201,
                nextRecurAt: nil,
                phase: nil,
                recur: nil,
                statusLiteral: "status",
                workTypeLiteral: "work-type-synced-c"
            ),
            WorkType(
                id: 5,
                createdAt: createdAtC,
                orgClaim: 8456,
                nextRecurAt: nextRecurAtC,
                phase: 93,
                recur: "recur-synced-new",
                statusLiteral: "status-synced-new",
                workTypeLiteral: "work-type-synced-d"
            ),
        ]
        XCTAssertEqual(expectedWorkTypes, actual.asExternalModel().workTypes.sorted(by: { a, b in
            a.id - b.id <= 0
        }))

        actual = try worksiteDao!.getWorksite(2)!
        let expectedWorkTypesB = [
            testWorkTypeRecord(24, worksiteId: 2).copy {
                $0.id = 6
                $0.workType = "work-type-a"
            },
            testWorkTypeRecord(26, worksiteId: 2).copy {
                $0.id = 7
                $0.workType = "work-type-b"
            },
        ]
        XCTAssertEqual(
            existingWorksites[1].copy {
                $0.address = "sync-address"
                $0.updatedAt = updatedAtB
            },
            actual.worksite
        )
        XCTAssertEqual(expectedWorkTypesB, actual.workTypes)
    }

    /**
     * Locally modified worksites (and associated work types) are not synced
     */
    func testSyncSkipLocallyModified() async throws {
        // Insert existing
        var existingWorksites = [
            testWorksiteRecord(1, 1, "address", updatedAtA),
            testWorksiteRecord(2, 1, "address", updatedAtA),
        ]
        existingWorksites = try await insertWorksites(existingWorksites, previousSyncedAt)
        try await WorksiteTestUtil.setModifiedAt(dbQueue!, 2, updatedAtA)

        try await dbQueue!.write({ db in
            for workType in [
                testWorkTypeRecord(1, workType: "work-type-a", worksiteId: 1),
                testWorkTypeRecord(11, workType: "work-type-b", worksiteId: 1),
                testWorkTypeRecord(22, workType: "work-type-a", worksiteId: 2),
                testWorkTypeRecord(24, workType: "work-type-b", worksiteId: 2),
            ] {
                var workType = workType
                try workType.insert(db)
            }
        })

        // Sync
        let syncingWorksites = [
            testWorksiteRecord(1, 1, "sync-address", updatedAtB),
            testWorksiteRecord(2, 1, "sync-address", updatedAtB),
        ]
        let syncingWorkTypes = [
            [
                // Update
                testWorkTypeRecord(
                    1,
                    status: "status-synced",
                    workType: "work-type-a",
                    worksiteId: 1
                ),
                // New
                testWorkTypeRecord(15, workType: "work-type-synced-a", worksiteId: 1),
            ],
            [
                testWorkTypeRecord(
                    22,
                    status: "status-synced",
                    workType: "work-type-a",
                    worksiteId: 2
                ),
                testWorkTypeRecord(
                    24,
                    status: "status-synced",
                    workType: "work-type-b",
                    worksiteId: 2
                ),
                testWorkTypeRecord(
                    26,
                    status: "status-synced",
                    workType: "work-type-c",
                    worksiteId: 2
                ),
            ],
        ]
        // Sync new and existing
        let syncedAt = previousSyncedAt.addingTimeInterval(499_999.seconds)
        try await worksiteDao!.syncWorksites(syncingWorksites, syncingWorkTypes, syncedAt)

        // Assert

        // Worksite synced
        var actual = try worksiteDao!.getWorksite(1)!
        XCTAssertEqual(
            existingWorksites[0].copy {
                $0.address = "sync-address"
                $0.updatedAt = updatedAtB
            },
            actual.worksite
        )
        var expectedWorkTypes = [
            testWorkTypeRecord(1, worksiteId: 1).copy {
                $0.id = 1
                $0.status = "status-synced"
                $0.workType = "work-type-a"
            },
            testWorkTypeRecord(15, worksiteId: 1).copy {
                $0.id = 6
                $0.workType = "work-type-synced-a"
            },
        ]
        XCTAssertEqual(expectedWorkTypes, actual.workTypes)

        // Worksite not synced
        actual = try worksiteDao!.getWorksite(2)!
        expectedWorkTypes = [
            testWorkTypeRecord(22, workType: "work-type-a", worksiteId: 2).copy { $0.id = 3 },
            testWorkTypeRecord(24, workType: "work-type-b", worksiteId: 2).copy { $0.id = 4 },
        ]
        XCTAssertEqual(existingWorksites[1], actual.worksite)
        XCTAssertEqual(expectedWorkTypes, actual.workTypes)
    }
}
