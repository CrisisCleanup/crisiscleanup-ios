import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorkTypeDaoTests: XCTestCase {
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
        let worksite = testWorksiteRecord(1, 1, "address", updatedAtA)
        _ = try await WorksiteTestUtil.insertWorksites(dbQueue!, now, [worksite])
    }

    /**
     * Updates short work type data with full network data
     */
    func testSyncWorkTypeFullFromShort() async throws {
        try await dbQueue!.write({ db in
            for workType in [
                testWorkTypeRecord(111),
                testWorkTypeRecord(112, workType: "work-type-b"),
            ] {
                try workType.syncUpsert(db)
            }
        })

        let workTypeFull = fullWorkTypeRecord(
            networkId: 111,
            createdAt: now,
            workType: "work-type-a"
        )
        try await dbQueue!.write({ db in
            try workTypeFull.syncUpsert(db)
        })
        let expected = [
            // Update
            workTypeFull.copy { $0.id = 1 },
            // Unchanged
            testWorkTypeRecord(112, workType: "work-type-b").copy { $0.id = 2},
        ]
        let actual = try await dbQueue!.write({ db in
            try WorkTypeRecord
                .fetchAll(db)
        })
            .sorted(by: { a, b in
                a.id! - b.id! <= 0
            })
        XCTAssertEqual(expected, actual)
    }

    /**
     * Updates full work type data with short network data
     *
     * created_at is not overwritten
     */
    func testSyncWorkTypeShortFromFull() async throws {
        let workTypeFull = fullWorkTypeRecord(
            networkId: 111,
            createdAt: now,
            workType: "work-type-a"
        )
        try await dbQueue!.write({ db in
            for workType in [
                workTypeFull,
                testWorkTypeRecord(112, workType: "work-type-b"),
            ] {
                try workType.syncUpsert(db)
            }
        })

        try await dbQueue!.write({ db in
            for workType in [
                testWorkTypeRecord(111, status: "s", workType: "work-type-a"),
                testWorkTypeRecord(350, status: "sa", workType: "wa"),
            ] {
                try workType.syncUpsert(db)
            }
        })

        let expecteds = [
            // Update
            testWorkTypeRecord(111, status: "s", workType: "work-type-a").copy {
                $0.id = 1
                $0.createdAt = now
            },
            // Unchanged
            testWorkTypeRecord(112, workType: "work-type-b").copy { $0.id = 2 },
            // Inserts
            testWorkTypeRecord(350, status: "sa", workType: "wa").copy { $0.id = 4 },
        ]
        let actual = try await dbQueue!.write({ db in
            try WorkTypeRecord
                .fetchAll(db)
        })
            .sorted(by: { a, b in
                a.id! - b.id! <= 0
            })
        XCTAssertEqual(expecteds, actual)
    }
}

internal func testWorkTypeRecord(
    _ networkId: Int64,
    status: String = "status",
    workType: String = "work-type-a",
    orgClaim: Int64? = 201,
    worksiteId: Int64 = 1,
    createdAt: Date? = nil,
    nextRecurAt: Date? = nil,
    phase: Int? = nil,
    recur: String? = nil,
    id: Int64? = nil
) -> WorkTypeRecord {
    WorkTypeRecord(
        id: id,
        networkId: networkId,
        worksiteId: worksiteId,
        createdAt: createdAt,
        orgClaim: orgClaim,
        nextRecurAt: nextRecurAt,
        phase: phase,
        recur: recur,
        status: status,
        workType: workType
    )
}

internal func fullWorkTypeRecord(
    networkId: Int64 = 111,
    createdAt: Date,
    status: String = "status-full",
    workType: String = "work-type-full",
    orgClaim: Int64 = 4851
) -> WorkTypeRecord {
    testWorkTypeRecord(
        networkId,
        status: status,
        workType: workType,
        orgClaim: orgClaim,
        worksiteId: 1,
        createdAt: createdAt,
        nextRecurAt: createdAt.addingTimeInterval(5413.seconds),
        phase: 53,
        recur: "recur"
    )
}
