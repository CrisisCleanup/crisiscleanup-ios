import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteChangeUpdateSyncTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)
    private var createdAtA = Date.now
    private var updatedAtA = Date.now
    private var createdAtB = Date.now
    private var updatedAtB = Date.now
    private var createdAtC = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteChangeDao: WorksiteChangeDao!

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
            appDb,
            uuidGenerator: uuidGenerator,
            changeSerializer: changeSerializer,
            appVersionProvider: WorksiteTestUtil.testAppVersionProvider,
            syncLogger: WorksiteTestUtil.silentSyncLogger
        )

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }

        testIncidentId = WorksiteTestUtil.testIncidents.last!.id
    }
}
