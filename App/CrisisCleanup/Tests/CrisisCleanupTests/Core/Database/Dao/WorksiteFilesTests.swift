import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class WorksiteFilesTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var worksiteDao: WorksiteDao!

    override func setUp() async throws {
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

    private func seedData() async throws -> (Int64, Int64) {
        let incidentId = WorksiteTestUtil.testIncidents.first!.id
        let worksites = [
            testWorksiteRecord(52, incidentId, "incident-address", now),
            testWorksiteRecord(62, incidentId, "incident-address", now),
        ]
        let insertedWorksites = try await insertWorksites(worksites, now)

        let worksiteIdB = insertedWorksites[0].id!
        let worksiteIdC = insertedWorksites[1].id!

        let networkFiles = [
            testNetworkFileRecord(1, now, 11, fullUrl: "full-url", tag: "after"),
            testNetworkFileRecord(2, now, 12, fullUrl: "full-url"),
            testNetworkFileRecord(3, now, 13, fullUrl: "full-url", tag: "before"),
            testNetworkFileRecord(4, now, 14, fullUrl: "full-url"),
            testNetworkFileRecord(5, now, 15, fullUrl: "full-url", tag: "after"),
            testNetworkFileRecord(6, now, 16, fullUrl: "full-url"),
            testNetworkFileRecord(7, now, 17, fullUrl: "full-url"),
            testNetworkFileRecord(8, now, 18, fullUrl: "full-url", tag: "before"),
        ]
        func worksiteToNetworkFile(
            _ worksiteId: Int64,
            _ networkFileId: Int64
        ) -> WorksiteToNetworkFileRecord {
            WorksiteToNetworkFileRecord(id: worksiteId, networkFileId: networkFileId)
        }
        let worksiteToNetworkFiles = [
            worksiteToNetworkFile(worksiteIdB, 1),
            worksiteToNetworkFile(worksiteIdC, 2),
            worksiteToNetworkFile(worksiteIdB, 3),
            worksiteToNetworkFile(worksiteIdC, 4),
            worksiteToNetworkFile(worksiteIdB, 5),
            worksiteToNetworkFile(worksiteIdC, 6),
            worksiteToNetworkFile(worksiteIdC, 7),
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
            networkFileLocalImage(3),
        ]

        func localImageRecord(
            _ id: Int64,
            _ worksiteId: Int64,
            _ tag: String
        ) -> WorksiteLocalImageRecord {
            WorksiteLocalImageRecord(
                id: id,
                worksiteId: worksiteId,
                localDocumentId: "doc-id-\(id)",
                uri: "",
                tag: tag,
                rotateDegrees: 0
            )
        }
        let localImages = [
            localImageRecord(1, worksiteIdB, "after"),
            localImageRecord(21, worksiteIdB, "before"),
            localImageRecord(358, worksiteIdC, "before"),
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
            for record in localImages {
                try record.insert(db)
            }
        }

        return (
            worksiteIdB,
            worksiteIdC
        )
    }

    func testPopulatedWorksiteFiles() async throws {
        let (worksiteIdB, _) = try await seedData()

        let caseImages = try worksiteDao.getWorksiteFiles(worksiteIdB)?.toCaseImages()
        let expected = [
            CaseImage(id: 21, isNetworkImage: false, thumbnailUri: "", imageUri: "", tag: "before"),
            CaseImage(id: 3, isNetworkImage: true, thumbnailUri: "", imageUri: "full-url", tag: "before"),
            CaseImage(id: 1, isNetworkImage: false, thumbnailUri: "", imageUri: "", tag: "after"),
            CaseImage(id: 1, isNetworkImage: true, thumbnailUri: "", imageUri: "full-url", tag: "after"),
        ]
        XCTAssertEqual(caseImages, expected)
    }
}
