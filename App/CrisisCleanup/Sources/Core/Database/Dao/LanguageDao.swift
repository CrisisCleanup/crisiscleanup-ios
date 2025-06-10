import Combine
import Foundation
import GRDB

public class LanguageDao {
    private let database: AppDatabase
    private let reader: DatabaseReader
    private let logger: AppLogger

    init(
        _ database: AppDatabase,
        logger: AppLogger,
    ) {
        self.database = database
        reader = database.reader
        self.logger = logger
    }

    func getLanguageCount() -> Int {
        try! reader.read { try LanguageRecord.fetchCount($0) }
    }

    func streamLanguages() -> AnyPublisher<[Language], Error> {
        ValueObservation
            .tracking(fetchLanguages(_:))
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .map { $0.map { r in r.asExternalModel() } }
            .eraseToAnyPublisher()
    }
    private func fetchLanguages(_ db: Database) throws -> [LanguageRecord] {
        try LanguageRecord.all().orderedByKey().fetchAll(db)
    }

    func getLanguageTranslations(_ key: String) -> LanguageTranslations? {
        try! reader.read {
            try fetchLanguageTranslations($0, key)
        }?.asExternalModel(logger)
    }

    func streamLanguageTranslations(_ key: String) -> AnyPublisher<LanguageTranslations?, Error> {
        ValueObservation
            .tracking { try self.fetchLanguageTranslations($0, key) }
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .map { $0?.asExternalModel(self.logger) }
            .eraseToAnyPublisher()
    }
    private func fetchLanguageTranslations(_ db: Database, _ key: DatabaseValueConvertible) throws -> LanguageTranslationRecord? {
        try LanguageTranslationRecord.fetchOne(db, key: key)
    }

    func upsertLanguageTranslation(_ languageTranslation: LanguageTranslationRecord) async throws {
        try await database.upsertLanguageTranslation(languageTranslation)
    }

    func saveLanguages(_ languages: [LanguageTranslationRecord]) async throws {
        try await database.insertIgnoreLanguages(languages)
    }
}

extension AppDatabase {
    fileprivate func upsertLanguageTranslation(_ languageTranslation: LanguageTranslationRecord) async throws {
        try await dbWriter.write { db in
            try languageTranslation.upsert(db)
        }
    }

    fileprivate func insertIgnoreLanguages(
        _ languages: [LanguageTranslationRecord]
    ) async throws {
        try await dbWriter.write { db in
            try languages.forEach { language in
                _ = try language.insertAndFetch(db, onConflict: .ignore)
            }
        }
    }
}
