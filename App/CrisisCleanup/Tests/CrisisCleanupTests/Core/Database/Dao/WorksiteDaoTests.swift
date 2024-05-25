import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteDaoTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)

    private var previousSyncedAt: Date = Date.now
    private var createdAtA: Date = Date.now
    private var updatedAtA: Date = Date.now
    private var createdAtB: Date = Date.now
    private var updatedAtB: Date = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!

    override func setUp() async throws {
        previousSyncedAt = now.addingTimeInterval(-9999.seconds)
        createdAtA = previousSyncedAt.addingTimeInterval(-854812.seconds)
        updatedAtA = createdAtA.addingTimeInterval(78458.seconds)
        createdAtB = createdAtA.addingTimeInterval(3512.seconds)
        updatedAtB = createdAtB.addingTimeInterval(452.seconds)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        worksiteDao = WorksiteDao(
            appDb,
            WorksiteTestUtil.silentSyncLogger,
            WorksiteTestUtil.silentAppLogger
        )

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }
    }

    private func existingRecord(
        _ networkId: Int64,
        incidentId: Int64 = 1,
        address: String = "test-address",
        createdAt: Date? = nil,
        caseNumberOrder: Int64 = 0
    ) -> WorksiteRecord {
        testWorksiteRecord(
            networkId,
            incidentId,
            address,
            updatedAtA,
            createdAt: createdAt,
            caseNumberOrder: caseNumberOrder
        )
    }

    /**
     * Syncing worksites data insert into db without fail
     */
    func testSyncNewWorksites() async throws {
        // Insert existing
        var existingWorksites = [
            existingRecord(1, createdAt: createdAtA),
            existingRecord(2),
            existingRecord(3, incidentId: 23, address: "test-address-23"),
        ]
        existingWorksites = try await WorksiteTestUtil.insertWorksites(dbQueue, previousSyncedAt, existingWorksites)

        // Sync
        let syncingWorksites = [
            testWorksiteRecord(4, 1, "missing-created-at-4", updatedAtB),
            testWorksiteFullRecord(5, 1, createdAtB).copy {
                $0.createdAt = nil
            },
            testWorksiteRecord(6, 1, "created-at-6", updatedAtB, createdAt: createdAtB),
            testWorksiteFullRecord(7, 1, createdAtB),
        ]
        let syncingWorkTypes = syncingWorksites.map { _ in [WorkTypeRecord]() }
        // Sync new and existing
        let syncedAt = previousSyncedAt.addingTimeInterval(487.seconds)
        try await worksiteDao.syncWorksites(syncingWorksites, syncingWorkTypes, syncedAt)

        // Assert

        var expected = [existingWorksites[2]]
        var actual = try worksiteDao.getWorksites(23).map { $0.worksite }
        XCTAssertEqual(expected, actual)

        actual = try worksiteDao.getWorksites(1).map { $0.worksite }

        // Order by updated_at desc id desc
        // updatedA > updatedB > fullA.updated_at
        XCTAssertEqual([2, 1, 6, 4, 7, 5], actual.map { $0.id })

        expected = [
            // First 2 are unchanged
            existingWorksites[1],
            existingWorksites[0],

            // Remaining are as inserted
            syncingWorksites[2].copy {
                $0.id = 6
            },
            syncingWorksites[0].copy {
                $0.id = 4
            },
            syncingWorksites[3].copy {
                $0.id = 7
            },
            syncingWorksites[1].copy {
                $0.id = 5
            },
        ]
        for (i, actualWorksite) in actual.enumerated() {
            XCTAssertEqual(expected[i], actualWorksite, "$i")
        }
    }

    /**
     * Synced updates to worksite data overwrite as expected
     *
     * - created_at does not overwrite if syncing data is nil
     */
    func testSyncUpdateWorksites() async throws {
        // Insert existing
        var existingWorksites = [
            existingRecord(1, createdAt: createdAtA),
            existingRecord(2),
            existingRecord(3, incidentId: 23, address: "test-address-23"),
            existingRecord(4, createdAt: createdAtA),
            existingRecord(5, caseNumberOrder: 52),
            existingRecord(6, createdAt: createdAtA),
            existingRecord(7, caseNumberOrder: 52)
        ]
        existingWorksites = try await WorksiteTestUtil.insertWorksites(dbQueue, previousSyncedAt, existingWorksites)

        // Sync
        let syncingWorksites = [
            // Not syncing 1
            // Not syncing 2
            // 3 is different incident

            // Modify 4 and 5 should keep original created_at
            testWorksiteRecord(4, 1, "missing-created-at-4", updatedAtB),
            testWorksiteFullRecord(5, 1, createdAtB).copy {
                $0.createdAt = nil
            },

            // Modify 6 and 7 should update created_at
            testWorksiteRecord(6, 1, "update-created-at-6", updatedAtB, createdAt: createdAtB),
            testWorksiteFullRecord(7, 1, createdAtB),
        ]
        let syncingWorkTypes = syncingWorksites.map { _ in [WorkTypeRecord]() }
        // Sync new and existing
        let syncedAt = previousSyncedAt.addingTimeInterval(487.seconds)
        try await worksiteDao.syncWorksites(syncingWorksites, syncingWorkTypes, syncedAt)

        // Assert

        var expected = [existingWorksites[2]]
        var actual = try worksiteDao.getWorksites(23).map { $0.worksite }

        XCTAssertEqual(expected, actual)

        actual = try worksiteDao.getWorksites(1).map { $0.worksite }

        // Order by updated_at desc id desc
        // updatedA > updatedB > fullA.updated_at
        XCTAssertEqual([2, 1, 6, 4, 7, 5], actual.map { $0.id })

        expected = [
            // First 2 are unchanged
            existingWorksites[1],
            existingWorksites[0],

            existingWorksites[5].copy {
                $0.address = "update-created-at-6"
                $0.updatedAt = updatedAtB
                $0.createdAt = createdAtB
            },
            // No change to created_at
            existingWorksites[3].copy {
                $0.address = "missing-created-at-4"
                $0.updatedAt = updatedAtB
            },
            testWorksiteFullRecord(7, 1, createdAtB, id: 7).copy {
                $0.id = 7
            },
            testWorksiteFullRecord(5, 1, createdAtB, id: 5).copy {
                $0.id = 5
                $0.createdAt = nil
                $0.updatedAt = createdAtB.addingTimeInterval(99.seconds)
            },
        ]
        for (i, actualWorksite) in actual.enumerated() {
            XCTAssertEqual(expected[i], actualWorksite, "$i")
        }
    }

    /**
     * Full and short entity data must be different for test integrity
     *
     * Update as fields change.
     */
    func testWorksiteEntitiesAreDifferent() {
        let networkId = Int64(41)
        let incidentId = Int64(53)
        let full = testWorksiteFullRecord(networkId, incidentId, createdAtA)
        let short = testWorksiteShortRecord(networkId, incidentId, createdAtA)
        XCTAssertNotEqual(full.address, short.address)
        XCTAssertNotEqual(full.caseNumber, short.caseNumber)
        XCTAssertNotEqual(full.city, short.city)
        XCTAssertNotEqual(full.county, short.county)
        XCTAssertNotEqual(full.favoriteId, short.favoriteId)
        XCTAssertNotEqual(full.keyWorkTypeType, short.keyWorkTypeType)
        XCTAssertNotEqual(full.latitude, short.latitude)
        XCTAssertNotEqual(full.longitude, short.longitude)
        XCTAssertNotEqual(full.name, short.name)
        XCTAssertNotEqual(full.postalCode, short.postalCode)
        XCTAssertNotEqual(full.state, short.state)
        XCTAssertNotEqual(full.svi, short.svi)
        XCTAssertNotEqual(full.updatedAt, short.updatedAt)

        XCTAssertNotNil(full.autoContactFrequencyT)
        XCTAssertNotNil(full.email)
        XCTAssertNotNil(full.phone1)
        XCTAssertNotNil(full.phone2)
        XCTAssertNotNil(full.plusCode)
        XCTAssertNotNil(full.reportedBy)
        XCTAssertNotNil(full.what3Words)

        XCTAssertNil(short.autoContactFrequencyT)
        XCTAssertNil(short.email)
        XCTAssertNil(short.phone1)
        XCTAssertNil(short.phone2)
        XCTAssertNil(short.plusCode)
        XCTAssertNil(short.reportedBy)
        XCTAssertNil(short.what3Words)
    }

    /**
     * nilable worksite fields are nilable columns in db
     */
    func testSyncNewWorksitesShort() async throws {
        var existingWorksites = [
            testWorksiteShortRecord(1, 1, createdAtA),
        ]
        existingWorksites = try await WorksiteTestUtil.insertWorksites(dbQueue, previousSyncedAt, existingWorksites)

        let expected = [existingWorksites[0].copy { $0.id = 1 }]
        let actual = try worksiteDao.getWorksites(1).map { $0.worksite }
        XCTAssertEqual(expected, actual)
    }

    /**
     * Worksite db data coalesces certain nilable columns as expected
     */
    func testUpdateNewWorksitesShort() async throws {
        // Insert existing
        var existingWorksites = [
            testWorksiteShortRecord(1, 1, createdAtA),
            testWorksiteFullRecord(2, 1, createdAtA),
        ]
        existingWorksites = try await WorksiteTestUtil.insertWorksites(dbQueue, previousSyncedAt, existingWorksites)
        let existingWorksite = existingWorksites[1]

        // Sync
        let syncingWorksites = [
            // Missing created_at
            testWorksiteShortRecord(1, 1, createdAtB).copy {
                $0.createdAt = nil
                $0.address = "expected-address"
            },
            testWorksiteShortRecord(2, 1, createdAtB).copy {
                $0.address = "expected-address"
                $0.caseNumber = "expected-case 875"
                $0.caseNumberOrder = 875
                $0.city = "expected-city"
                $0.county = "expected-county"
                $0.favoriteId = existingWorksite.favoriteId! + 1
                $0.keyWorkTypeType = "expected-key-work-type"
                $0.keyWorkTypeStatus = "expected-key-work-status"
                $0.latitude = existingWorksite.latitude + 0.01
                $0.longitude = existingWorksite.longitude + 0.01
                $0.name = "expected-name"
                $0.postalCode = "expected-code"
                $0.state = "expected-state"
                $0.svi = existingWorksite.svi! + 0.1
                $0.updatedAt = existingWorksite.updatedAt.addingTimeInterval(11.seconds)
            },
        ]
        let syncingWorkTypes = syncingWorksites.map { _ in [WorkTypeRecord]() }
        // Sync
        let syncedAt = previousSyncedAt.addingTimeInterval(487.seconds)
        try await worksiteDao.syncWorksites(syncingWorksites, syncingWorkTypes, syncedAt)

        // Assert
        let expected = [
            // Updates certain fields
            syncingWorksites[0].copy {
                $0.id = 1
                $0.createdAt = createdAtA
            },
            // Does not overwrite coalescing columns/fields
            testWorksiteFullRecord(2, 1, createdAtB).copy {
                $0.id = 2
                $0.address = "expected-address"
                $0.caseNumber = "expected-case 875"
                $0.caseNumberOrder = 875
                $0.city = "expected-city"
                $0.county = "expected-county"
                $0.favoriteId = existingWorksite.favoriteId! + 1
                $0.keyWorkTypeType = "expected-key-work-type"
                $0.keyWorkTypeOrgClaim = nil
                $0.keyWorkTypeStatus = "expected-key-work-status"
                $0.latitude = existingWorksite.latitude + 0.01
                $0.longitude = existingWorksite.longitude + 0.01
                $0.name = "expected-name"
                $0.postalCode = "expected-code"
                $0.state = "expected-state"
                $0.svi = existingWorksite.svi! + 0.1
                $0.updatedAt = existingWorksite.updatedAt.addingTimeInterval(11.seconds)
            },
        ]
        let actual = try worksiteDao.getWorksites(1).map { $0.worksite }
        XCTAssertEqual(expected, actual)
    }

    // TODO Sync existing worksite where the incident changes. Change back as well?
}

func testWorksiteRecord(
    _ networkId: Int64,
    _ incidentId: Int64,
    _ address: String,
    _ updatedAt: Date,
    createdAt: Date? = nil,
    caseNumberOrder: Int64 = 0,
    id: Int64? = nil
) -> WorksiteRecord {
    WorksiteRecord(
        id: id,
        networkId: networkId,
        incidentId: incidentId,
        address: address,
        autoContactFrequencyT: "",
        caseNumber: "",
        caseNumberOrder: caseNumberOrder,
        city: "",
        county: "",
        createdAt: createdAt,
        email: "",
        favoriteId: nil,
        keyWorkTypeType: "",
        keyWorkTypeOrgClaim: nil,
        keyWorkTypeStatus: "",
        latitude: 0.0,
        longitude: 0.0,
        name: "",
        phone1: "",
        phone2: nil,
        plusCode: nil,
        postalCode: "",
        reportedBy: 0,
        state: "",
        svi: nil,
        what3Words: nil,
        updatedAt: updatedAt,
        isLocalFavorite: false
    )
}

// Defines all fields setting updated_at to be relative to createdAt
func testWorksiteFullRecord(
    _ networkId: Int64,
    _ incidentId: Int64,
    _ createdAt: Date,
    id: Int64? = nil
) -> WorksiteRecord {
    WorksiteRecord(
        id: id,
        networkId: networkId,
        incidentId: incidentId,
        address: "123 address st",
        autoContactFrequencyT: "enum.never",
        caseNumber: "case52",
        caseNumberOrder: 52,
        city: "city 123",
        county: "county 123",
        createdAt: createdAt,
        email: "test123@email.com",
        favoriteId: 4134,
        keyWorkTypeType: "key-type-type",
        keyWorkTypeOrgClaim: 652,
        keyWorkTypeStatus: "key-type-status",
        latitude: 414.353,
        longitude: -534.15,
        name: "full worksite",
        phone1: "345-414-7825",
        phone2: "835-621-8938",
        plusCode: "code 123",
        postalCode: "83425",
        reportedBy: 7835,
        state: "ED",
        svi: 6.235,
        what3Words: "what,three,words",
        updatedAt: createdAt.addingTimeInterval(99.seconds),
        isLocalFavorite: false
    )
}


// Defines all fields not nilable
func testWorksiteShortRecord(
    _ networkId: Int64,
    _ incidentId: Int64,
    _ createdAt: Date,
    id: Int64? = nil
) -> WorksiteRecord {
    WorksiteRecord(
        id: id,
        networkId: networkId,
        incidentId: incidentId,
        address: "123 address st short",
        autoContactFrequencyT: nil,
        caseNumber: "case short96",
        caseNumberOrder: 96,
        city: "city short 123",
        county: "county short 123",
        createdAt: createdAt,
        email: nil,
        favoriteId: 895,
        keyWorkTypeType: "key-short-type",
        keyWorkTypeOrgClaim: nil,
        keyWorkTypeStatus: "key-short-status",
        latitude: 856.353,
        longitude: -157.15,
        name: "short worksite",
        phone1: nil,
        phone2: nil,
        plusCode: nil,
        postalCode: "83425-shrt",
        reportedBy: nil,
        state: "SH",
        svi: 0.548,
        what3Words: nil,
        updatedAt: createdAt.addingTimeInterval(66.seconds),
        isLocalFavorite: false
    )
}
