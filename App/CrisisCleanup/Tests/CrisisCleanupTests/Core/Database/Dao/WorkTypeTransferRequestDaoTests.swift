import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorkTypeTransferRequestDaoTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var createdAtA: Date = Date.now
    private var updatedAtA: Date = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!
    private var requestDao: WorkTypeTransferRequestDao? = nil

    override func setUp() async throws {
        createdAtA = now.addingTimeInterval(-8845.seconds)
        updatedAtA = createdAtA.addingTimeInterval(848.seconds)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        worksiteDao = WorksiteDao(appDb, WorksiteTestUtil.silentSyncLogger)
        requestDao = WorkTypeTransferRequestDao(appDb)

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }

        }
        let worksite = testWorksiteRecord(1, 1, "address", createdAtA)
        _ = try await WorksiteTestUtil.insertWorksites(dbQueue, now, [worksite])
    }

    func testSyncRequests() async throws {
        let existingRequests = [
            testWorkTypeTransferRequestRecord("work-type-a", 331, createdAtA, networkId: 851),
            testWorkTypeTransferRequestRecord("work-type-b", 331, createdAtA),
            testWorkTypeTransferRequestRecord("work-type-c", 331, createdAtA, networkId: 93),
            testWorkTypeTransferRequestRecord("work-type-d", 331, createdAtA),
        ]
        try await dbQueue.write { db in
            for record in existingRequests {
                var record = record
                try record.insert(db, onConflict: .ignore)
            }
        }

        let newRequests = [
            // Update
            testWorkTypeTransferRequestRecord(
                "work-type-b",
                331,
                updatedAtA,
                reason: "reason-updated",
                networkId: 593,
                toOrg: 513,
                rejectedAt: updatedAtA,
                approvedRejectedReason: "rejected"
            ),
            // Update
            testWorkTypeTransferRequestRecord(
                "work-type-c",
                331,
                updatedAtA,
                reason: "reason-updated",
                networkId: 93,
                toOrg: 513,
                approvedAt: updatedAtA,
                approvedRejectedReason: "approved"
            ),
            // New, different byOrg
            testWorkTypeTransferRequestRecord(
                "work-type-c",
                129,
                updatedAtA,
                reason: "reason-new",
                networkId: 93,
                toOrg: 513,
                // Production data should have distinct network IDs. For testing purposes.
                approvedAt: updatedAtA
            ),
            // New work type
            testWorkTypeTransferRequestRecord(
                "work-type-e",
                331,
                updatedAtA,
                toOrg: 591
            ),
        ]
        try await requestDao!.syncUpsert(newRequests)

        let expected = {
            let recordIds: [Int64] = [2, 3, 7, 8]
            // let reasons = ["reason", "reason", "reason-new", "reason"]
            return [
                [testWorkTypeTransferRequestRecord("work-type-d", 331, createdAtA, id: 4)],
                newRequests.enumerated().map { (index, record) in
                    record.copy {
                        $0.id = recordIds[index]
                        //  $0.reason = reasons[index]
                    }
                }
            ]
                .joined()
                .sorted { (a, b) in a.id! < b.id! }
        }()
        let actual = try await dbQueue.read { db in
            try WorkTypeRequestRecord.filter(WorkTypeRequestRecord.Columns.worksiteId == 1)
                .fetchAll(db)
        }
            .sorted { (a, b) in a.id! < b.id! }
        XCTAssertEqual(expected, actual)
    }
}

private func testWorkTypeTransferRequestRecord(
    _ workType: String,
    _ byOrg: Int64,
    _ createdAt: Date = dateNowRoundedSeconds,
    reason: String = "reason",
    worksiteId: Int64 = 1,
    id: Int64? = nil,
    networkId: Int64 = -1,
    toOrg: Int64 = 0,
    approvedAt: Date? = nil,
    rejectedAt: Date? = nil,
    approvedRejectedReason: String = ""
) -> WorkTypeRequestRecord {
    WorkTypeRequestRecord(
        id: id,
        networkId: networkId,
        worksiteId: worksiteId,
        workType: workType,
        reason: reason,
        byOrg: byOrg,
        toOrg: toOrg,
        createdAt: createdAt,
        approvedAt: approvedAt,
        rejectedAt: rejectedAt,
        approvedRejectedReason: approvedRejectedReason
    )
}
