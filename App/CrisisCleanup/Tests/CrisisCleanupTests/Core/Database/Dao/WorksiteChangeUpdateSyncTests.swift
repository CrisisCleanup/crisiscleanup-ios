import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteChangeUpdateSyncTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)
    private var createdAtA: Date!

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!
    private var worksiteChangeDao: WorksiteChangeDao!

    private var testIncidentId: Int64 = 0

    private var uuidGenerator: UuidGenerator = TestUuidGenerator()
    private var changeSerializer: WorksiteChangeSerializerMock!

    override func setUp() async throws {
        createdAtA = now.addingTimeInterval(-4.days)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        let syncLogger = WorksiteTestUtil.silentSyncLogger
        worksiteDao = WorksiteDao(
            appDb,
            WorksiteTestUtil.silentSyncLogger,
            WorksiteTestUtil.silentAppLogger
        )
        uuidGenerator = TestUuidGenerator()
        changeSerializer = .init()
        worksiteChangeDao = WorksiteChangeDao(
            appDb,
            uuidGenerator: uuidGenerator,
            phoneNumberParser: RegexPhoneNumberParser(),
            changeSerializer: changeSerializer,
            appVersionProvider: WorksiteTestUtil.testAppVersionProvider,
            syncLogger: syncLogger
        )

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }

        testIncidentId = WorksiteTestUtil.testIncidents.last!.id

        try await seedDb()
    }

    private func makeRootRecord() -> WorksiteRootRecord {
        WorksiteRootRecord(
            id: 51,
            syncUuid: "sync-uuid-1",
            localModifiedAt: createdAtA,
            syncedAt: epoch0,
            localGlobalUuid: "local-global-uuid-1",
            isLocalModified: true,
            syncAttempt: 0,
            networkId: -1,
            incidentId: testIncidentId
        )
    }

    func seedDb() async throws {
        let rootRecord = makeRootRecord()
        try await dbQueue.write { db in
            var record = rootRecord
            try record.insert(db)

            var changeRecord = self.testWorksiteChange(51, saveAttempt: 2)
            try changeRecord.insert(db)

            var copyRoot = rootRecord.copy {
                $0.id = 65
                $0.localGlobalUuid = "local-global-uuid-2"
            }
            try copyRoot.insert(db)

            let changesB = [
                self.testWorksiteChange(65),
                self.testWorksiteChange(65),
                self.testWorksiteChange(65),
            ]
            for record in changesB {
                var record = record
                try record.insert(db)
            }

            copyRoot = rootRecord.copy {
                $0.id = 77
                $0.localGlobalUuid = "local-global-uuid-3"
            }
            try copyRoot.insert(db)

            let changesC = [
                self.testWorksiteChange(77, archiveAction: WorksiteChangeArchiveAction.synced),
                self.testWorksiteChange(77, saveAttempt: 1),
                self.testWorksiteChange(77, saveAttempt: 2),
                self.testWorksiteChange(77, saveAttempt: 3),
                self.testWorksiteChange(77, saveAttempt: 4),
            ]
            for record in changesC {
                var record = record
                try record.insert(db)
            }
        }
    }

    func testUpdateSyncIds() async throws {
        try await dbQueue.write { db in
            var worksiteRecord = testWorksiteRecord(
                -1,
                 self.testIncidentId,
                 "",
                 self.createdAtA,
                 createdAt: self.createdAtA,
                 id: 51
            )
            try worksiteRecord.insert(db)

            var flagRecord = testFlagRecord(
                -1,
                 51,
                 self.createdAtA,
                 "reason-a"
            )
            try flagRecord.insert(db)

            var noteRecord = testNotesRecord(
                -1,
                 51,
                 self.createdAtA,
                 "note-a",
                 localGlobalUuid: "local-global-uuid-2"
            )
            try noteRecord.insert(db)

            let workTypeRecords = [
                testWorkTypeRecord(
                    -1,
                     workType: "work-type-a",
                     worksiteId: 51
                ),
                testWorkTypeRecord(
                    -1,
                     workType: "work-type-b",
                     worksiteId: 51
                ),
            ]
            for record in workTypeRecords {
                var record = record
                try record.insert(db)
            }

            let requestRecords = [
                self.testWorkTypeRequestRecord(
                    -1,
                     51,
                     "work-type-a",
                     byOrg: 538
                ),
                self.testWorkTypeRequestRecord(
                    34,
                    51,
                    "work-type-b",
                    byOrg: 623
                ),
                self.testWorkTypeRequestRecord(
                    58,
                    51,
                    "work-type-b",
                    byOrg: 538
                ),
            ]
            for record in requestRecords {
                var record = record
                try record.insert(db)
            }
        }

        try await worksiteChangeDao.updateSyncIds(
            worksiteId: 51,
            organizationId: 538,
            ids: WorksiteSyncResult.ChangeIds(
                networkWorksiteId: 884,
                flagIdMap: [1: 43, 4: 83],
                noteIdMap: [9: 358, 1: 385],
                workTypeIdMap: [2: 837, 83: 358, 1: 385],
                workTypeKeyMap: ["work-type-c": 358, "work-type-b": 124],
                workTypeRequestIdMap: [
                    "work-type-a": 524,
                    "work-type-b": 529,
                ]
            )
        )

        XCTAssertEqual(884, worksiteDao.getWorksiteNetworkId(51))

        let flagDao = WorksiteFlagDao(appDb)
        XCTAssertEqual(
            [PopulatedIdNetworkId(id: 1, networkId: 43)],
            try flagDao.getNetworkedIdMap(51)
        )

        let noteDao = WorksiteNoteDao(appDb)
        XCTAssertEqual(
            [PopulatedIdNetworkId(id: 1, networkId: 385)],
            try noteDao.getNetworkedIdMap(51)
        )

        let workTypeDao = WorkTypeDao(appDb)
        XCTAssertEqual(
            [
                PopulatedIdNetworkId(id: 1, networkId: 385),
                PopulatedIdNetworkId(id: 2, networkId: 124),
            ],
            try workTypeDao.getNetworkedIdMap(51)
                .sorted(by: { a, b in a.id < b.id })
        )

        XCTAssertEqual(
            [
                PopulatedIdNetworkId(id: 1, networkId: 524),
                PopulatedIdNetworkId(id: 2, networkId: 34),
                PopulatedIdNetworkId(id: 3, networkId: 529),
            ],
            try dbQueue.getWorkTypeRequestNetworkedIdMap(51)
                .sorted(by: { a, b in a.id < b.id })
        )

        try await worksiteChangeDao.updateSyncIds(
            worksiteId: 51,
            organizationId: 538,
            ids: WorksiteSyncResult.ChangeIds(
                networkWorksiteId: -1,
                flagIdMap: [1: -1],
                noteIdMap: [9: -1],
                workTypeIdMap: [2: -1],
                workTypeKeyMap: ["work-type-c": -1],
                workTypeRequestIdMap: ["work-type-b": -1]
            )
        )

        XCTAssertEqual(884, worksiteDao.getWorksiteNetworkId(51))

        XCTAssertEqual(
            [PopulatedIdNetworkId(id: 1, networkId: 43)],
            try flagDao.getNetworkedIdMap(51)
        )

        XCTAssertEqual(
            [PopulatedIdNetworkId(id: 1, networkId: 385)],
            try noteDao.getNetworkedIdMap(51)
        )

        XCTAssertEqual(
            [
                PopulatedIdNetworkId(id: 1, networkId: 385),
                PopulatedIdNetworkId(id: 2, networkId: 124),
            ],
            try workTypeDao.getNetworkedIdMap(51)
                .sorted(by: { a, b in a.id < b.id })
        )

        XCTAssertEqual(
            [
                PopulatedIdNetworkId(id: 1, networkId: 524),
                PopulatedIdNetworkId(id: 2, networkId: 34),
                PopulatedIdNetworkId(id: 3, networkId: 529),
            ],
            try dbQueue.getWorkTypeRequestNetworkedIdMap(51)
                .sorted(by: { a, b in a.id < b.id })
        )
    }

    func testUpdateSyncChanges_noSyncChanges() async throws {
        try await worksiteChangeDao.updateSyncChanges(worksiteId: 77, changeResults: [])

        let actual = try dbQueue.getChangeRecordsOrderId(77)
        let expected = [
            testWorksiteChange(77, id: 6, saveAttempt: 1),
            testWorksiteChange(77, id: 7, saveAttempt: 2),
            testWorksiteChange(77, id: 8, saveAttempt: 3),
            testWorksiteChange(77, id: 9, saveAttempt: 4),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testUpdateSyncChanges_oneFail() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 51,
            changeResults: [testChangeResult(1, isFail: true)]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(51)
        let expected = [
            testWorksiteChange(
                51,
                id: 1,
                createdAt: createdAtA,
                saveAttempt: 3,
                saveAttemptAt: actual[0].saveAttemptAt
            ),
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
    }

    func testUpdateSyncChanges_onePartiallySuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 51,
            changeResults: [testChangeResult(1, isPartiallySuccessful: true)]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(51)
        let expected = [
            testWorksiteChange(
                51,
                id: 1,
                createdAt: createdAtA,
                saveAttempt: 3,
                archiveAction: WorksiteChangeArchiveAction.partiallySynced,
                saveAttemptAt: actual[0].saveAttemptAt
            ),
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
    }

    func testUpdateSyncChanges_oneSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 51,
            changeResults: [testChangeResult(1, isSuccessful: true)]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(51)
        XCTAssertEqual([], actual)
    }

    func testUpdateSyncChanges_manyNoneSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 65,
            changeResults: [
                testChangeResult(2, isPartiallySuccessful: true),
                testChangeResult(3, isFail: true),
                testChangeResult(4, isFail: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(65)
        let expected = [
            testWorksiteChange(
                65,
                id: 2,
                createdAt: createdAtA,
                saveAttempt: 1,
                archiveAction: WorksiteChangeArchiveAction.partiallySynced,
                saveAttemptAt: actual[0].saveAttemptAt
            ),
            testWorksiteChange(
                65,
                id: 3,
                createdAt: createdAtA,
                saveAttempt: 1,
                saveAttemptAt: actual[1].saveAttemptAt
            ),
            testWorksiteChange(
                65,
                id: 4,
                createdAt: createdAtA,
                saveAttempt: 1,
                saveAttemptAt: actual[2].saveAttemptAt
            ),
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
        XCTAssertNearNow(actual[1].saveAttemptAt)
        XCTAssertNearNow(actual[2].saveAttemptAt)
    }

    func testUpdateSyncChanges_manyFirstSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 65,
            changeResults: [
                testChangeResult(2, isSuccessful: true),
                testChangeResult(3, isPartiallySuccessful: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(65)
        let expected = [
            testWorksiteChange(
                65,
                id: 3,
                createdAt: createdAtA,
                saveAttempt: 1,
                archiveAction: WorksiteChangeArchiveAction.partiallySynced,
                saveAttemptAt: actual[0].saveAttemptAt
            ),
            testWorksiteChange(65, id: 4),
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
    }

    func testUpdateSyncChanges_manySecondSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 65,
            changeResults: [
                testChangeResult(2),
                testChangeResult(3, isSuccessful: true),
                testChangeResult(4, isFail: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(65)
        let expected = [
            testWorksiteChange(
                65,
                id: 4,
                createdAt: createdAtA,
                saveAttempt: 1,
                saveAttemptAt: actual[0].saveAttemptAt
            )
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
    }

    func testUpdateSyncChanges_manyMiddleSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 77,
            changeResults: [
                testChangeResult(6, isFail: true),
                testChangeResult(7, isSuccessful: true),
                testChangeResult(8, isPartiallySuccessful: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(77)
        let expected = [
            testWorksiteChange(
                77,
                id: 8,
                createdAt: createdAtA,
                saveAttempt: 4,
                archiveAction: WorksiteChangeArchiveAction.partiallySynced,
                saveAttemptAt: actual[0].saveAttemptAt
            ),
            testWorksiteChange(77, id: 9, saveAttempt: 4)
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
    }

    func testUpdateSyncChanges_manySecondToLastSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 77,
            changeResults: [
                testChangeResult(6, isSuccessful: true),
                testChangeResult(7, isFail: true),
                testChangeResult(8, isSuccessful: true),
                testChangeResult(9, isFail: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(77)
        let expected = [
            testWorksiteChange(
                77,
                id: 9,
                createdAt: createdAtA,
                saveAttempt: 5,
                saveAttemptAt: actual[0].saveAttemptAt
            )
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertNearNow(actual[0].saveAttemptAt)
    }

    func testUpdateSyncChanges_manyLastSuccessful() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 77,
            changeResults: [
                testChangeResult(6, isPartiallySuccessful: true),
                testChangeResult(7, isFail: true),
                testChangeResult(8, isSuccessful: true),
                testChangeResult(9, isSuccessful: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(77)
        XCTAssertEqual([], actual)
    }

    /**
     * Simulates when changes are added after a sync started before changes are updated
     */
    func testUpdateSyncChanges_insertBeforeUpdatingChanges() async throws {
        try await worksiteChangeDao.updateSyncChanges(
            worksiteId: 65,
            changeResults: [
                testChangeResult(2),
                testChangeResult(3, isSuccessful: true),
            ]
        )

        let actual = try dbQueue.getChangeRecordsOrderId(65)
        let expected = [testWorksiteChange(65, id: 4)]
        XCTAssertEqual(expected, actual)
    }

    private func testWorksiteChange(
        _ worksiteId: Int64,
        id: Int64? = nil,
        saveAttempt: Int = 0,
        archiveAction: WorksiteChangeArchiveAction = WorksiteChangeArchiveAction.pending
    ) -> WorksiteChangeRecord {
        testWorksiteChange(
            worksiteId,
            id: id,
            createdAt: createdAtA,
            saveAttempt: saveAttempt,
            archiveAction: archiveAction,
            saveAttemptAt: epoch0
        )
    }

    private func testWorksiteChange(
        _ worksiteId: Int64,
        id: Int64? = nil,
        createdAt: Date,
        saveAttempt: Int = 0,
        archiveAction: WorksiteChangeArchiveAction = WorksiteChangeArchiveAction.pending,
        saveAttemptAt: Date
    ) -> WorksiteChangeRecord {
        WorksiteChangeRecord(
            id: id,
            appVersion: 1,
            organizationId: 1,
            worksiteId: worksiteId,
            syncUuid: "",
            changeModelVersion: 1,
            changeData: "change-data",
            createdAt: createdAt,
            saveAttempt: saveAttempt,
            archiveAction: archiveAction.literal,
            saveAttemptAt: saveAttemptAt
        )
    }

    private func testChangeResult(
        _ id: Int64,
        isSuccessful: Bool = false,
        isPartiallySuccessful: Bool = false,
        isFail: Bool = false
    ) -> WorksiteSyncResult.ChangeResult {
        WorksiteSyncResult.ChangeResult(
            id: id,
            isSuccessful: isSuccessful,
            isPartiallySuccessful: isPartiallySuccessful,
            isFail: isFail,
            error: nil
        )
    }

    private func testWorkTypeRequestRecord(
        _ networkId: Int64,
        _ worksiteId: Int64,
        _ workType: String,
        byOrg: Int64 = 52,
        reason: String = "reason",
        toOrg: Int64 = 83,
        createdAt: Date = dateNowRoundedSeconds,
        id: Int64? = nil
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
            approvedAt: nil,
            rejectedAt: nil,
            approvedRejectedReason: ""
        )
    }
}

extension DatabaseQueue {
    func getWorkTypeRequestNetworkedIdMap(_ worksiteId: Int64) throws -> [PopulatedIdNetworkId] {
        try read { db in
            try WorkTypeRequestRecord
                .all()
                .selectIdNetworkIdColumns()
                .filter(WorkTypeRequestRecord.Columns.networkId > -1)
                .asRequest(of: PopulatedIdNetworkId.self)
                .fetchAll(db)
        }
    }

    func getChangeRecordsOrderId(_ worksiteId: Int64) throws -> [WorksiteChangeRecord] {
        try read { db in
            try WorksiteChangeRecord
                .all()
                .filter(WorksiteChangeRecord.Columns.worksiteId == worksiteId)
                .order(WorksiteChangeRecord.Columns.id)
                .fetchAll(db)
        }
    }
}
