import Combine
import Foundation
import GRDB
@testable import CrisisCleanup

func initializeTestDb() throws -> (DatabaseQueue, AppDatabase) {
    let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
    let appDb = try AppDatabase(dbQueue)
    return (dbQueue, appDb)
}

class WorksiteTestUtil {
    static let testIncidents = [
        testIncidentRecord(1, 6525),
        testIncidentRecord(23, 152),
        testIncidentRecord(456, 514),
    ]

    static func insertWorksites(
        _ dbQueue: DatabaseQueue,
        _ syncedAt: Date,
        _ worksites: [WorksiteRecord]
    ) async throws -> [WorksiteRecord] {
        return try await dbQueue.write { db in
            var records = [WorksiteRecord]()
            for worksite in worksites {
                let id = try WorksiteRootRecord.insertOrRollback(db, syncedAt, worksite.networkId, worksite.incidentId)
                var updated = worksite.copy { $0.id = id }
                try updated.insert(db)
                records.append(updated)
            }
            return records
        }
    }

    static func setModifiedAt(
        _ dbQueue: DatabaseQueue,
        _ worksiteId: Int64,
        _ modifiedAt: Date
    ) async throws {
        try await dbQueue.write({ db in
            try db.execute(
                sql:
                    """
                    UPDATE worksiteRoot
                    SET localModifiedAt=:modifiedAt, isLocalModified=1
                    WHERE id=:id
                    """,
                arguments: [
                    "id": worksiteId,
                    "modifiedAt": modifiedAt,
                ]
            )
        })
    }

    internal static let testTranslator = TestTranslator()
    internal static let silentSyncLogger = SilentSyncLogger()
}

internal class TestTranslator : KeyTranslator {
    private let translationCountSubject = CurrentValueSubject<Int, Never>(0)
    var translationCount: any Publisher<Int, Never>

    init() {
        self.translationCount = translationCountSubject
    }

    func translate(_ phraseKey: String) -> String? {
        "\(phraseKey)-translated"
    }

    func callAsFunction(_ phraseKey: String) -> String {
        translate(phraseKey)!
    }

}

internal class SilentSyncLogger : SyncLogger {
    func log(_ message: String, _ details: String, _ type: String) -> SyncLogger { self }
    func clear() -> SyncLogger { self }
    func flush() {}
}

internal func testIncidentRecord(
    _ id: Int64,
    _ startAtSeconds: Double
) -> IncidentRecord {
    IncidentRecord(
        id: id,
        startAt: Date(timeIntervalSince1970: startAtSeconds),
        name: "",
        shortName: "",
        type: "",
        activePhoneNumber: nil,
        turnOnRelease: false,
        isArchived: false
    )
}
