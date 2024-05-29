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
                let id: Int64
                if worksite.id == nil {
                    id = try WorksiteRootRecord.insertOrRollback(db, syncedAt, worksite.networkId, worksite.incidentId)
                } else {
                    id = try WorksiteRootRecord.create(
                        syncedAt: syncedAt,
                        networkId: worksite.networkId,
                        incidentId: worksite.incidentId,
                        id: worksite.id!
                    )
                    .insertAndFetch(db, onConflict: .rollback)!.id!
                }
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
    internal static let testAppVersionProvider = TestAppVersionProvider()
    internal static let silentAppLogger = SilentAppLogger()
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

    func t(_ phraseKey: String) -> String {
        translate(phraseKey)!
    }
}

internal class SilentSyncLogger : SyncLogger {
    var type: String = ""

    func log(_ message: String, _ details: String, _ type: String) {}
    func clear() {}
    func flush() {}
}

internal class SilentAppLogger : AppLogger {
    func logDebug(_ items: Any...) {}
    func logError(_ e: Error) {}
    func logCapture(_ message: String) {}
    func setAccontId(_ id: String) {}
}

internal class TestUuidGenerator: UuidGenerator {
    private var counter = 0

    func uuid() -> String {
        counter += 1
        return "uuid-\(counter)"
    }
}

internal class TestAppVersionProvider: AppVersionProvider {
    let version: (Int64, String) = (81, "1.0.81")
    var versionString: String { version.1 }
    var buildNumber: Int64 { version.0 }
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
