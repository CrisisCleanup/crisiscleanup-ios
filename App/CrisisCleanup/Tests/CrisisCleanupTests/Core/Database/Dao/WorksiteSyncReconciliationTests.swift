import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteSyncReconciliationTests: XCTestCase {
    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!
    private var recentWorksiteDao: RecentWorksiteDao!

    override func setUp() async throws {
        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        worksiteDao = WorksiteDao(
            appDb,
            WorksiteTestUtil.silentSyncLogger,
            WorksiteTestUtil.silentAppLogger,
        )
        recentWorksiteDao = RecentWorksiteDao(appDb)

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }

        let now = dateNowRoundedSeconds
        let worksiteCreatedAt = now.addingTimeInterval(-10.days)
        let insertAt = now.addingTimeInterval(-1.days)
        _ = try await WorksiteTestUtil.insertWorksites(
            dbQueue,
            insertAt,
            [
                testWorksiteFullRecord(
                    534,
                    23,
                    worksiteCreatedAt.addingTimeInterval(1.hours)
                ),
                testWorksiteFullRecord(
                    48,
                    1,
                    worksiteCreatedAt.addingTimeInterval(2.hours)
                ),
                testWorksiteFullRecord(
                    1654,
                    456,
                    worksiteCreatedAt.addingTimeInterval(3.hours)
                ),
                testWorksiteFullRecord(
                    9,
                    23,
                    worksiteCreatedAt.addingTimeInterval(4.hours)
                ),
                testWorksiteFullRecord(
                    987,
                    23,
                    worksiteCreatedAt.addingTimeInterval(5.hours)
                ),
            ],
        )
    }

    func testSyncNetworkChangedIncidents() async throws {
        let viewedAt = dateNowRoundedSeconds
        let recentViews = [
            RecentWorksiteRecord(id: 4, incidentId: 23, viewedAt: viewedAt),
            RecentWorksiteRecord(id: 1, incidentId: 23, viewedAt: viewedAt),
        ]
        for recent in recentViews {
            try await recentWorksiteDao.upsert(recent)
        }

        func makeChangeIds(_ incidentId: Int64, _ networkWorksiteId: Int64) -> IncidentWorksiteIds {
            makeIncidentWorksiteIds(incidentId, 0, networkWorksiteId)
        }

        let changes = try await worksiteDao.syncNetworkChangedIncidents(
            changeCandidates: [
                makeChangeIds(1, 534),
                makeChangeIds(1, 987),
                makeChangeIds(23, 1654),
            ],
            stepInterval: 2,
        )

        let expectedChanges = [
            makeIncidentWorksiteIds(1, 1, 534),
            makeIncidentWorksiteIds(1, 5, 987),
            makeIncidentWorksiteIds(23, 3, 1654),
        ]
        XCTAssertEqual(expectedChanges, changes)

        let orderedChanges = [
            expectedChanges[0],
            makeIncidentWorksiteIds(1, 2, 48),
            expectedChanges[2],
            makeIncidentWorksiteIds(23, 4, 9),
            expectedChanges[1],
        ]
        let worksiteIdsA = try dbQueue.getWorksiteRecords()
        XCTAssertEqual(orderedChanges, worksiteIdsA)
        let worksiteIdsB = try dbQueue.getRootWorksiteRecords()
        XCTAssertEqual(orderedChanges, worksiteIdsB)

        let recents = try dbQueue.getRecentWorksites()
        let expectedRecents = [
            makeRecentWorksiteRecord(1, 1, viewedAt),
            makeRecentWorksiteRecord(4, 23, viewedAt),
        ]
        XCTAssertEqual(expectedRecents, recents)
    }

    func testSyncDeletedWorksites() async throws {
        try await worksiteDao.syncDeletedWorksites(networkIds: [987, 1654, 48], stepInterval: 2)

        let networkWorksiteIds = try dbQueue.getWorksiteRecords()
            .map { $0.networkId }
            .sorted()
        XCTAssertEqual([9, 534], networkWorksiteIds)
    }
}

fileprivate func makeIncidentWorksiteIds(
    _ incidentId: Int64,
    _ worksiteId: Int64,
    _ networkWorksiteId: Int64,
) -> IncidentWorksiteIds {
    IncidentWorksiteIds(incidentId: incidentId, id: worksiteId, networkId: networkWorksiteId)
}

fileprivate func makeRecentWorksiteRecord(
    _ id: Int64,
    _ incidentId: Int64,
    _ viewedAt: Date,
) -> RecentWorksiteRecord {
    RecentWorksiteRecord(id: id, incidentId: incidentId, viewedAt: viewedAt)
}

extension DatabaseQueue {
    fileprivate func getWorksiteRecords() throws -> [IncidentWorksiteIds] {
        try read { db in
            try WorksiteRecord
                .order(WorksiteRecord.Columns.id)
                .asRequest(of: IncidentWorksiteIds.self)
                .fetchAll(db)
        }
    }

    fileprivate func getRootWorksiteRecords() throws -> [IncidentWorksiteIds] {
        try read { db in
            try WorksiteRootRecord
                .order(WorksiteRootRecord.Columns.id)
                .asRequest(of: IncidentWorksiteIds.self)
                .fetchAll(db)
        }
    }

    fileprivate func getRecentWorksites() throws -> [RecentWorksiteRecord] {
        try read { db in
            try RecentWorksiteRecord
                .order(RecentWorksiteRecord.Columns.id)
                .fetchAll(db)
        }
    }
}
