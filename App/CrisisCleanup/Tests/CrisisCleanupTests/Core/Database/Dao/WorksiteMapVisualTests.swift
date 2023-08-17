import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteMapVisualTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)

    private var previousSyncedAt: Date = Date.now
    private var createdAtA: Date = Date.now
    private var updatedAtA: Date = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!

    override func setUp() async throws {
        previousSyncedAt = now.addingTimeInterval(-9999.seconds)
        createdAtA = previousSyncedAt.addingTimeInterval(-854812.seconds)
        updatedAtA = createdAtA.addingTimeInterval(78458.seconds)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        worksiteDao = WorksiteDao(appDb, WorksiteTestUtil.silentSyncLogger)

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }
    }

    func testWorksiteMapVisuals() async throws {
        let worksite = WorksiteRecord(
            id: nil,
            networkId: 734,
            incidentId: 1,
            address: "",
            autoContactFrequencyT: "",
            caseNumber: "",
            caseNumberOrder: 0,
            city: "",
            county: "",
            createdAt: createdAtA,
            email: "",
            favoriteId: 334,
            keyWorkTypeType: "key-work-type",
            keyWorkTypeOrgClaim: 64,
            keyWorkTypeStatus: "key-work-type-status",
            latitude: 34.5,
            longitude: -18.53235135,
            name: "",
            phone1: "",
            phone2: "",
            plusCode: "",
            postalCode: "",
            reportedBy: nil,
            state: "",
            svi: nil,
            what3Words: "",
            updatedAt: updatedAtA,
            isLocalFavorite: false
        )
        _ = try await WorksiteTestUtil.insertWorksites(dbQueue, now, [worksite])

        try await dbQueue.write({ db in
            for workType in [
                testWorkTypeRecord(1, workType: "work-type-a", worksiteId: 1),
                testWorkTypeRecord(11, workType: "work-type-b", worksiteId: 1),
            ] {
                var workType = workType
                try workType.insert(db, onConflict: .ignore)
            }

            for flag in [
                testFlagRecord(11, 1, self.createdAtA, "flag-a"),
                testFlagRecord(12, 1, self.createdAtA, "flag.worksite_high_priority"),
            ] {
                var flag = flag
                try flag.insert(db, onConflict: .ignore)
            }
        })

        let actual = try worksiteDao.getWorksitesMapVisual(
            1,
            south: -90,
            north: 90,
            west: -180,
            east: 180,
            limit: 99,
            offset: 0
        )
            .map { $0.asExternalModel() }
        let expected = [WorksiteMapMark(
            id: 1,
            incidentId: 1,
            latitude: 34.5,
            longitude: -18.53235135,
            statusClaim: WorkTypeStatusClaim.make("key-work-type-status", 64),
            workType: .unknown,
            workTypeCount: 2,
            isFavorite: true,
            isHighPriority: true
        )]
        XCTAssertEqual(expected, actual)
    }
}
