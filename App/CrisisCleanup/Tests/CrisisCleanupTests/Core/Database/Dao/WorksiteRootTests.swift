import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteRootRecordTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var previousSyncedAt: Date = Date.now
    private var createdAtA: Date = Date.now
    private var updatedAtA: Date = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!

    override func setUp() async throws {
        previousSyncedAt = now.addingTimeInterval(-999_999.0.seconds)
        createdAtA = previousSyncedAt.addingTimeInterval(-4_523.0.seconds)
        updatedAtA = createdAtA.addingTimeInterval(15_531.seconds)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }
    }

    func testWorksiteRootSyncUpdate() async throws {
        let worksiteId = try await dbQueue.write({ db in
            try WorksiteRootRecord.insertOrRollback(db, self.previousSyncedAt, 41, 1)
        })

        let inserted = try await dbQueue.write({ db in
            try WorksiteRootRecord
                .all()
                .filter(id: worksiteId)
                .fetchOne(db)
        })!
        XCTAssertEqual(41, inserted.networkId)
        XCTAssertEqual(1, inserted.incidentId)

        try await dbQueue.write({ db in
            do {
                try WorksiteRootRecord.syncUpdate(
                    db,
                    id: worksiteId,
                    expectedLocalModifiedAt: self.createdAtA,
                    syncedAt: self.updatedAtA,
                    networkId: inserted.networkId,
                    incidentId: inserted.incidentId
                )

                let worksite = testWorksiteShortRecord(inserted.networkId, inserted.incidentId, self.now)
                    .copy { $0.id = worksiteId }
                _ = try worksite.insertAndFetch(db)
            } catch is GenericError {
            }
        })

        let fetchedA = try await dbQueue.write({ db in
            let root = try WorksiteRootRecord
                .all()
                .filter(id: worksiteId)
                .fetchOne(db)!
            let worksite = try WorksiteRecord
                .all()
                .filter(id: worksiteId)
                .fetchOne(db)
            return (root, worksite)
        })
        XCTAssertEqual(inserted, fetchedA.0)
        XCTAssertEqual(nil, fetchedA.1)

        try await dbQueue.write({ db in
            try WorksiteRootRecord.syncUpdate(
                db,
                id: worksiteId,
                expectedLocalModifiedAt: inserted.localModifiedAt,
                syncedAt: self.updatedAtA,
                networkId: inserted.networkId,
                incidentId: inserted.incidentId
            )

            let worksite = testWorksiteShortRecord(inserted.networkId, inserted.incidentId, self.now)
                .copy { $0.id = worksiteId }
            _ = try worksite.insertAndFetch(db)
        })
        let fetchedB = try await dbQueue.write({ db in
            let root = try WorksiteRootRecord
                .all()
                .filter(id: worksiteId)
                .fetchOne(db)!
            let worksite = try WorksiteRecord
                .all()
                .filter(id: worksiteId)
                .fetchOne(db)!
            return (root, worksite)
        })
        let expectedRoot = WorksiteRootRecord(
            id: worksiteId,
            syncUuid: "",
            localModifiedAt: inserted.localModifiedAt,
            syncedAt: updatedAtA,
            localGlobalUuid: "",
            isLocalModified: false,
            syncAttempt: 0,
            networkId: 41,
            incidentId: 1
        )
        XCTAssertEqual(expectedRoot, fetchedB.0)
        let expectedWorksite = testWorksiteShortRecord(41, 1, now).copy { $0.id = worksiteId }
        XCTAssertEqual(expectedWorksite, fetchedB.1)
    }
}
