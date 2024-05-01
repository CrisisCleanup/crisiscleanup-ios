import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class NetworkFileTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds
    private var epoch0 = Date(timeIntervalSince1970: 0)

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!

    override func setUp() async throws {
        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }
    }

    private func insertWorksites(
        _ worksites: [WorksiteRecord],
        _ syncedAt: Date
    ) async throws -> [WorksiteRecord] {
        try await WorksiteTestUtil.insertWorksites(
            dbQueue,
            syncedAt,
            worksites
        )
    }

    private func seedData() async throws -> (Int64, Int64, Int64) {
        let incidentId = WorksiteTestUtil.testIncidents.first!.id
        let worksites = [
            testWorksiteRecord(52, incidentId, "incident-address", now),
            testWorksiteRecord(62, incidentId, "incident-address", now),
            testWorksiteRecord(72, incidentId, "incident-address", now),
        ]
        let insertedWorksites = try await insertWorksites(worksites, now)

        let worksiteIdA = insertedWorksites[2].id!
        let worksiteIdB = insertedWorksites[0].id!
        let worksiteIdC = insertedWorksites[1].id!

        let networkFiles = [
            testNetworkFileRecord(1, now, 11),
            testNetworkFileRecord(2, now, 12),
            testNetworkFileRecord(3, now, 13),
            testNetworkFileRecord(4, now, 14),
            testNetworkFileRecord(5, now, 15),
            testNetworkFileRecord(6, now, 16),
            testNetworkFileRecord(7, now, 17),
            testNetworkFileRecord(8, now, 18),
        ]
        func worksiteToNetworkFile(
            _ worksiteId: Int64,
            _ networkFileId: Int64
        ) -> WorksiteToNetworkFileRecord {
            WorksiteToNetworkFileRecord(id: worksiteId, networkFileId: networkFileId)
        }
        let worksiteToNetworkFiles = [
            worksiteToNetworkFile(worksiteIdB, 1),
            worksiteToNetworkFile(worksiteIdA, 2),
            worksiteToNetworkFile(worksiteIdB, 3),
            worksiteToNetworkFile(worksiteIdC, 4),
            worksiteToNetworkFile(worksiteIdB, 5),
            worksiteToNetworkFile(worksiteIdB, 6),
            worksiteToNetworkFile(worksiteIdA, 7),
            worksiteToNetworkFile(worksiteIdB, 8),
        ]

        func networkFileLocalImage(
            _ id: Int64,
            _ isDeleted: Bool = false
        ) -> NetworkFileLocalImageRecord {
            NetworkFileLocalImageRecord(
                id: id,
                isDeleted: isDeleted,
                rotateDegrees: 0
            )
        }
        let networkFileLocalImages = [
            networkFileLocalImage(8, true),
            networkFileLocalImage(1),
            networkFileLocalImage(5, true),
            networkFileLocalImage(7),
            networkFileLocalImage(3, true),
        ]

        try await dbQueue.write{ db in
            for record in networkFiles {
                try record.insert(db)
            }
            for record in worksiteToNetworkFiles {
                try record.insert(db)
            }
            for record in networkFileLocalImages {
                try record.insert(db)
            }
        }

        return (
            worksiteIdA,
            worksiteIdB,
            worksiteIdC
        )
    }

    func testDeleteDeletedFiles() async throws {
        let (
            worksiteIdA,
            worksiteIdB,
            worksiteIdC
        ) = try await seedData()

        func getFileIds() async throws -> [[Int64]] {
            try await dbQueue.read { db in
                let fileIds = try NetworkFileRecord
                    .select(NetworkFileRecord.Columns.id)
                    .asRequest(of: Int64.self)
                    .fetchAll(db)
                let xrIds = try WorksiteToNetworkFileRecord
                    .all()
                    .fetchAll(db)
                    .map {( $0.id, $0.networkFileId )}
                let localImageIds = try NetworkFileLocalImageRecord
                    .select(NetworkFileLocalImageRecord.Columns.id)
                    .order(NetworkFileLocalImageRecord.Columns.id.asc)
                    .asRequest(of: Int64.self)
                    .fetchAll(db)
                return [
                    fileIds,
                    xrIds.map { $0.0 },
                    xrIds.map { $0.1 },
                    localImageIds,
                ]
            }
        }

        try await dbQueue.write { db in
            try NetworkFileRecord.deleteDeleted(
                db, worksiteIdC, Set([1, 2, 3, 4, 5, 6, 7, 8])
            )
        }

        let actualNotDeleted = try await getFileIds()
        XCTAssertEqual(
            [8, 8, 8, 5],
            actualNotDeleted.map { $0.count }
        )

        try await dbQueue.write { db in
            try NetworkFileRecord.deleteDeleted(
                db, worksiteIdB, Set([3, 4, 6, 7, 8])
            )
        }

        let actualDeleted = try await getFileIds()
        XCTAssertEqual(
            [
                [1, 2, 3, 4, 6, 7, 8],
                [
                    worksiteIdB,
                    worksiteIdA,
                    worksiteIdB,
                    worksiteIdC,
                    worksiteIdB,
                    worksiteIdA,
                    worksiteIdB,
                ],
                [1, 2, 3, 4, 6, 7, 8],
                [1, 3, 7, 8],
            ],
            actualDeleted
        )
    }

    func testGetDeletedFileIds() async throws {
        let (
            worksiteIdA,
            worksiteIdB,
            worksiteIdC
        ) = try await seedData()

        let localImageDao = LocalImageDao(appDb)

        let deletedA = try localImageDao.getDeletedPhotoFileIds(worksiteIdA)
        let expectedA = [Int64]()
        XCTAssertEqual(deletedA, expectedA)

        let deletedB = try localImageDao.getDeletedPhotoFileIds(worksiteIdB)
            .sorted(by: { a, b in a < b })
        let expectedB: [Int64] = [13, 15, 18]
        XCTAssertEqual(deletedB, expectedB)

        let deletedC = try localImageDao.getDeletedPhotoFileIds(worksiteIdC)
        let expectedC = [Int64]()
        XCTAssertEqual(deletedC, expectedC)
    }
}

internal func testNetworkFileRecord(
    _ id: Int64,
    _ createdAt: Date,
    _ fileId: Int64,
    fullUrl: String? = nil,
    tag: String? = nil
) -> NetworkFileRecord {
    NetworkFileRecord(
        id: id,
        createdAt: createdAt,
        fileId: fileId,
        fileTypeT: "file-type",
        fullUrl: fullUrl,
        largeThumbnailUrl: nil,
        mimeContentType: "content-type",
        smallThumbnailUrl: nil,
        tag: tag,
        title: nil,
        url: "url"
    )
}
