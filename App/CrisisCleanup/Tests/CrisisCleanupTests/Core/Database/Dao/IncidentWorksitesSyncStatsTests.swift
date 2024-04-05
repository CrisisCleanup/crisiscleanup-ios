import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

class IncidentWorksiteSyncStatsDaoTests: XCTestCase {
    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var syncStatDao: WorksiteSyncStatDao!

    private var testIncidentId: Int64 = 0

    override func setUp() async throws {
        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        syncStatDao = WorksiteSyncStatDao(appDb)

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }

        testIncidentId = WorksiteTestUtil.testIncidents.last!.id
    }

    func testFullStats() async throws {
        let syncStartA = Date.now
        let attemptedSyncA = Date.now.addingTimeInterval(2.minutes)
        let statsRecord = WorksiteSyncStatRecord(
            id: testIncidentId,
            syncStart: syncStartA,
            targetCount: 200,
            pagedCount: 340,
            successfulSync: attemptedSyncA,
            attemptedSync: attemptedSyncA,
            attemptedCounter: 1,
            appBuildVersionCode: 2
        )
        try await syncStatDao.upsertStats(statsRecord)

        let syncStartB = Date.now.addingTimeInterval(1.hours)
        let attemptedSyncB = Date.now.addingTimeInterval(1.days)
        let secondaryStatsRecord = IncidentWorksitesSecondarySyncStatsRecord(
            id: testIncidentId,
            syncStart: syncStartB,
            targetCount: 642,
            pagedCount: 35,
            successfulSync: nil,
            attemptedSync: attemptedSyncB,
            attemptedCounter: 1,
            appBuildVersionCode: 23
        )
        try await syncStatDao.upsertSecondaryStats(secondaryStatsRecord)

        if let fullSyncStats = try await dbQueue.read({ db in
            try self.syncStatDao.fetchFullSyncStats(db, self.testIncidentId)
        }) {
            let actualStats = fullSyncStats.stats
            var expectedStats = statsRecord.asExternalModel()
            XCTAssertEqual(actualStats.syncStart.timeIntervalSince1970.seconds, syncStartA.timeIntervalSince1970.seconds, accuracy: 1.0e-3)
            XCTAssertEqual(actualStats.syncAttempt.successfulSeconds, attemptedSyncA.timeIntervalSince1970.seconds, accuracy: 1.0e-3)
            XCTAssertEqual(actualStats.syncAttempt.attemptedSeconds, attemptedSyncA.timeIntervalSince1970.seconds, accuracy: 1.0e-3)

            expectedStats = expectedStats.copy { stats in
                stats.syncStart = actualStats.syncStart
                stats.syncAttempt = stats.syncAttempt.copy { attempt in
                    attempt.successfulSeconds = actualStats.syncAttempt.successfulSeconds
                    attempt.attemptedSeconds = actualStats.syncAttempt.attemptedSeconds
                }
            }
            XCTAssertTrue(fullSyncStats.hasSyncedCore)
            XCTAssertEqual(actualStats, expectedStats)

            let actualSecondaryStatsOptional = fullSyncStats.secondaryStats
            XCTAssertNotNil(actualSecondaryStatsOptional)
            let actualSecondaryStats = actualSecondaryStatsOptional!
            var expectedSecondaryStats = secondaryStatsRecord.asExternalModel()

            XCTAssertEqual(actualSecondaryStats.syncStart.timeIntervalSince1970.seconds, syncStartB.timeIntervalSince1970.seconds, accuracy: 1.0e-3)
            XCTAssertEqual(actualSecondaryStats.syncAttempt.attemptedSeconds, attemptedSyncB.timeIntervalSince1970.seconds, accuracy: 1.0e-3)

            expectedSecondaryStats = expectedSecondaryStats.copy { stats in
                stats.syncStart = actualSecondaryStats.syncStart
                stats.syncAttempt = stats.syncAttempt.copy { attempt in
                    attempt.successfulSeconds = actualSecondaryStats.syncAttempt.successfulSeconds
                    attempt.attemptedSeconds = actualSecondaryStats.syncAttempt.attemptedSeconds
                }
            }
            XCTAssertEqual(actualSecondaryStats, expectedSecondaryStats)
        }
    }
}
