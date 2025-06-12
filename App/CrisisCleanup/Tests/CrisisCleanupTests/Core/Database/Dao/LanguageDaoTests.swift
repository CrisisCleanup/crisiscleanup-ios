import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class LanguageDaoTests: XCTestCase {
    private let logger = SilentAppLogger()

    private func insertLanguage(
        _ dbQueue: DatabaseQueue,
        _ languageTranslation: LanguageTranslationRecord
    ) throws {
        try dbQueue.write { db in
            try languageTranslation.insert(db)
        }
    }

    private func insertLanguage(_ dbQueue: DatabaseQueue) throws -> LanguageTranslationRecord {
        let languageTranslation = LanguageTranslationRecord(
            key: "language-a",
            name: "Language A",
            translationJson: nil,
            syncedAt: dateNowRoundedSeconds
        )
        try insertLanguage(dbQueue, languageTranslation)
        return languageTranslation
    }

    func testUpsert() async throws {
        let (dbQueue, appDb) = try initializeTestDb()

        let languageTranslation = try insertLanguage(dbQueue)
        let recordsFirst = try await appDb.reader.read { db in
            try LanguageTranslationRecord.fetchAll(db)
        }
        let expectedFirst = [languageTranslation]
        XCTAssertEqual(expectedFirst, recordsFirst)

        let languageTranslationUpdate = LanguageTranslationRecord(
            key: languageTranslation.key,
            name: "name-update",
            translationJson: "translation-json",
            syncedAt: dateNowRoundedSeconds.addingTimeInterval(1.days)
        )

        let languageDao = LanguageDao(appDb, logger: logger)
        try await languageDao.upsertLanguageTranslation(languageTranslationUpdate)

        let recordsSecond = try await appDb.reader.read { db in
            try LanguageTranslationRecord.fetchAll(db)
        }
        let expectedSecond = [languageTranslationUpdate]
        XCTAssertEqual(expectedSecond, recordsSecond)
    }

    func testSaveLanguages() async throws {
        let (dbQueue, appDb) = try initializeTestDb()

        let languageTranslation = try insertLanguage(dbQueue)

        let languageDao = LanguageDao(appDb, logger: logger)
        let languages = [
            LanguageTranslationRecord(
                key: languageTranslation.key,
                name: "name-update",
                translationJson: nil,
                syncedAt: nil
            ),
            LanguageTranslationRecord(
                key: "language-b",
                name: "name-b",
                translationJson: nil,
                syncedAt: dateNowRoundedSeconds
            )
        ]
        try await languageDao.saveLanguages(languages)

        let records = try await appDb.reader.read { db in
            try LanguageTranslationRecord.fetchAll(db)
        }
        let expected = [
            languageTranslation,
            languages[1]
        ]
        XCTAssertEqual(expected, records)
    }

    func testOrderedByKey() throws {
        let (dbQueue, _) = try initializeTestDb()

        let languageTranslationA = LanguageTranslationRecord(
            key: "language-a",
            name: "aa",
            translationJson: nil,
            syncedAt: dateNowRoundedSeconds.addingTimeInterval(1.hours)
        )
        let languageTranslationB = LanguageTranslationRecord(
            key: "language-b",
            name: "bb",
            translationJson: nil,
            syncedAt: dateNowRoundedSeconds.addingTimeInterval(-1.hours)
        )

        try dbQueue.write { db in
            try languageTranslationB.insert(db)
            try languageTranslationA.insert(db)
        }

        let languages = try dbQueue.read(LanguageRecord.all().orderedByKey().fetchAll)

        let expected = [
            languageTranslationA.asLanguageRecord(),
            languageTranslationB.asLanguageRecord()
        ]
        XCTAssertEqual(expected, languages)
    }
}

extension LanguageTranslationRecord {
    fileprivate func asLanguageRecord() -> LanguageRecord {
        return LanguageRecord(
            key: key,
            name: name
        )
    }
}
