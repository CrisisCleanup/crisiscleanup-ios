import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteChangeTransferDaoTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var createdAtA = Date.now
    private var updatedAtA = Date.now

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteChangeDao: WorksiteChangeDao!

    private var testIncidentId: Int64 = 0

    private var uuidGenerator: UuidGenerator = TestUuidGenerator()
    private var changeSerializer: WorksiteChangeSerializerMock!

    private func insertWorksite(_ worksite: Worksite) async throws -> EditWorksiteRecords {
        try await WorksiteChangeDaoTests.insertWorksite(dbQueue, uuidGenerator, now, worksite)
    }

    private func makeTestWorksite() -> Worksite {
        Worksite(
            id: 56,
            address: "address",
            autoContactFrequencyT: AutoContactFrequency.notOften.literal,
            caseNumber: "case-number",
            city: "city",
            county: "county",
            createdAt: createdAtA,
            email: "email",
            favoriteId: 623,
            incidentId: testIncidentId,
            keyWorkType: testWorkType(
                57,
                createdAtA,
                523,
                "status-b",
                "work-type-b"
            ),
            latitude: -5.23,
            longitude: -39.35,
            name: "name",
            networkId: 556,
            phone1: "phone1",
            phone2: "phone2",
            plusCode: "plus-code",
            postalCode: "postal-code",
            reportedBy: 573,
            state: "state",
            svi: 0.5,
            updatedAt: updatedAtA,
            what3Words: "what-3-words",
            workTypes: [
                testWorkType(
                    3,
                    createdAtA,
                    nil,
                    "status-a",
                    "work-type-a"
                ),
                testWorkType(
                    57,
                    createdAtA,
                    523,
                    "status-b",
                    "work-type-b"
                ),
                testWorkType(
                    58,
                    createdAtA,
                    nil,
                    "status-c",
                    "work-type-c"
                ),
                testWorkType(
                    59,
                    createdAtA,
                    481,
                    "status-d",
                    "work-type-d"
                ),
            ],
            isAssignedToOrgMember: true
        )
    }

    override func setUp() async throws {
        createdAtA = now.addingTimeInterval(-4.days)
        updatedAtA = createdAtA.addingTimeInterval(40.minutes)

        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        uuidGenerator = TestUuidGenerator()
        changeSerializer = .init()
        worksiteChangeDao = WorksiteChangeDao(
            appDb,
            uuidGenerator: uuidGenerator,
            phoneNumberParser: RegexPhoneNumberParser(),
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

        let testWorksite = self.makeTestWorksite()
        _ = try await insertWorksite(testWorksite)
        try await dbQueue.write { db in
            var flagRecord = WorksiteFlagRecord(
                id: 5,
                networkId: 55,
                worksiteId: testWorksite.id,
                action: "action",
                createdAt: self.createdAtA,
                isHighPriority: false,
                notes: "notes",
                reasonT: "reason",
                requestedAction: ""
            )
            try flagRecord.insert(db)

            var noteRecord = WorksiteNoteRecord(
                21,
                "",
                221,
                testWorksite.id,
                self.createdAtA,
                false,
                "note"
            )
            try noteRecord.insert(db)

            var workTypeRecord = WorkTypeRecord(
                id: 36,
                networkId: 336,
                worksiteId: testWorksite.id,
                createdAt: self.createdAtA,
                orgClaim: 167,
                nextRecurAt: nil,
                phase: 2,
                recur: nil,
                status: "status-existing",
                workType: "work-type-existing"
            )
            try workTypeRecord.insert(db)
            try db.updateWorkTypeNetworkId(3, 353)
            try db.updateWorkTypeNetworkId(57, 357)
        }
    }

    func testRequestNotSaved() async throws {
        let testWorksite = makeTestWorksite()

        let changeDao = worksiteChangeDao!
        try await changeDao.saveWorkTypeRequests(EmptyWorksite, 1, "reason", ["request"])
        try await changeDao.saveWorkTypeRequests(testWorksite, 0, "reason", ["request"])
        try await changeDao.saveWorkTypeRequests(testWorksite, 1, "", ["request"])
        try await changeDao.saveWorkTypeRequests(testWorksite, 1, "reason", [])
        try await changeDao.saveWorkTypeRequests(
            testWorksite,
            152,
            "reason",
            ["work-type-a", "work-type-c", "work-type-none"]
        )

        let requestCount = try dbQueue.getWorkTypeRequestCount()
        XCTAssertEqual(0, requestCount)

        XCTAssertEqual(0, changeSerializer.serializeCallsCount)
    }

    func testRequestClaimedUnclaimed() async throws {
        let testWorksite = makeTestWorksite()

        changeSerializer.mockClosure(
            false,
            EmptyWorksite,
            testWorksite,
            [5: 55],
            [21: 221],
            [
                3: 353,
                36: 336,
                57: 357,
            ],
            requestReasonExpected: "reason",
            requestWorkTypesExpected: ["work-type-b", "work-type-d"],
            mockReturn: (2, "serialized-work-type-requests")
        )

        let saveDate = now
        try await worksiteChangeDao!.saveWorkTypeRequests(
            testWorksite,
            152,
            "reason",
            ["work-type-b", "work-type-c", "work-type-d"],
            localModifiedAt: saveDate
        )

        let expected = [
            testWorkTypeTransferRequestRecord(
                id: 1,
                workType: "work-type-b",
                toOrg: 523,
                createdAt: saveDate
            ),
            testWorkTypeTransferRequestRecord(
                id: 2,
                workType: "work-type-d",
                toOrg: 481,
                createdAt: saveDate
            ),
        ]
        let actual = try dbQueue.selectWorkTypeRequests()
        XCTAssertEqual(expected, actual)

        let actualChanges = try dbQueue.selectWorksiteChanges(testWorksite.id)
        let expectedWorksiteChange = WorksiteChangeRecord(
            id: 1,
            appVersion: 81,
            organizationId: 152,
            worksiteId: testWorksite.id,
            syncUuid: "uuid-1",
            changeModelVersion: 2,
            changeData: "serialized-work-type-requests",
            createdAt: actualChanges.first!.createdAt
        )
        XCTAssertEqual([expectedWorksiteChange], actualChanges)
        XCTAssertNearNow(actualChanges.first!.createdAt)
    }

    func testReleaseNotSaved() async throws {
        let testWorksite = makeTestWorksite()

        let changeDao = worksiteChangeDao!
        try await changeDao.saveWorkTypeReleases(EmptyWorksite, 1, "reason", ["request"])
        try await changeDao.saveWorkTypeReleases(testWorksite, 0, "reason", ["request"])
        try await changeDao.saveWorkTypeReleases(testWorksite, 1, "", ["request"])
        try await changeDao.saveWorkTypeReleases(testWorksite, 1, "reason", [])
        try await changeDao.saveWorkTypeReleases(
            testWorksite,
            152,
            "reason",
            ["work-type-a", "work-type-c", "work-type-none"]
        )

        let requestCount = try dbQueue.getWorkTypeRequestCount()
        XCTAssertEqual(0, requestCount)

        XCTAssertEqual(0, changeSerializer.serializeCallsCount)
    }

    func testReleaseClaimedUnclaimed() async throws {
        let testWorksite = makeTestWorksite()

        var workTypeInsertId: Int64 = 60
        let worksiteChangeSerialize = testWorksite.copy { worksite in
            worksite.keyWorkType = testWorksite.keyWorkType?.copy {
                $0.id = 60
                $0.orgClaim = nil
                $0.statusLiteral = "status-b"
                $0.phase = nil
                $0.createdAt = now
            }
            worksite.workTypes = testWorksite.workTypes.map { workType in
                var workType = workType
                if workType.orgClaim != nil {
                    workType = WorkType(
                        id: workTypeInsertId,
                        createdAt: now,
                        statusLiteral: workType.statusLiteral,
                        workTypeLiteral: workType.workTypeLiteral
                    )
                    workTypeInsertId += 1
                }
                return workType
            }
        }
        changeSerializer.mockClosure(
            false,
            EmptyWorksite,
            worksiteChangeSerialize,
            [5: 55],
            [21: 221],
            [
                3: 353,
                36: 336,
            ],
            releaseReasonExpected: "reason",
            releaseWorkTypesExpected: ["work-type-b", "work-type-d"],
            mockReturn: (2, "serialized-work-type-releases")
        )

        let saveDate = now
        try await worksiteChangeDao!.saveWorkTypeReleases(
            testWorksite,
            152,
            "reason",
            ["work-type-b", "work-type-c", "work-type-d"],
            localModifiedAt: saveDate
        )

        func expectedWorkType(
            id: Int64,
            status: String,
            workType: String,
            networkId: Int64 = -1,
            orgClaim: Int64? = nil,
            createdAt: Date = createdAtA,
            phase: Int? = nil
        ) -> WorkTypeRecord {
            testWorkTypeRecord(
                networkId,
                status: status,
                workType: workType,
                orgClaim: orgClaim,
                worksiteId: testWorksite.id,
                createdAt: createdAt,
                phase: phase,
                id: id
            )
        }

        let expectedWorkTypes = [
            expectedWorkType(
                id: 3,
                status: "status-a",
                workType: "work-type-a",
                networkId: 353,
                phase: 2
            ),
            expectedWorkType(
                id: 60,
                status: "status-b",
                workType: "work-type-b",
                createdAt: now
            ),
            expectedWorkType(
                id: 58,
                status: "status-c",
                workType: "work-type-c",
                networkId: -1,
                phase: 2
            ),
            expectedWorkType(
                id: 61,
                status: "status-d",
                workType: "work-type-d",
                createdAt: now
            ),
            expectedWorkType(
                id: 36,
                status: "status-existing",
                workType: "work-type-existing",
                networkId: 336,
                orgClaim: 167,
                phase: 2
            ),
        ]
        let actualWorkTypes = try dbQueue.selectWorksiteWorkTypes(testWorksite.id)
            .sorted(by: { a, b in
                a.workType.localizedCompare(b.workType) == .orderedAscending
            })
        XCTAssertEqual(expectedWorkTypes, actualWorkTypes)

        let actualChanges = try dbQueue.selectWorksiteChanges(testWorksite.id)
        let expectedWorksiteChange = WorksiteChangeRecord(
            id: 1,
            appVersion: 81,
            organizationId: 152,
            worksiteId: testWorksite.id,
            syncUuid: "uuid-1",
            changeModelVersion: 2,
            changeData: "serialized-work-type-releases",
            createdAt: actualChanges.first!.createdAt
        )
        XCTAssertEqual([expectedWorksiteChange], actualChanges)
        XCTAssertNearNow(actualChanges.first!.createdAt)
    }
}

private func testWorkTypeTransferRequestRecord(
    id: Int64? = nil,
    workType: String,
    toOrg: Int64,
    byOrg: Int64 = 152,
    reason: String = "reason",
    worksiteId: Int64 = 56,
    createdAt: Date = dateNowRoundedSeconds,
    networkId: Int64 = -1
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

extension DatabaseQueue {
    internal func selectWorkTypeRequests() throws -> [WorkTypeRequestRecord] {
        try read { db in
            try WorkTypeRequestRecord
                .fetchAll(db)
        }
    }

    func getWorkTypeRequestCount() throws -> Int {
        try read { db in try WorkTypeRequestRecord.fetchCount(db) }
    }
}
