import Combine
import Foundation
import GRDB

public class LanguageDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getLanguageCount() -> Int {
        try! reader.read { try LanguageRecord.fetchCount($0) }
    }

    func streamLanguages() -> AnyPublisher<[Language], Error> {
        ValueObservation
            .tracking(fetchLanguages(_:))
            .publisher(in: reader)
            .map { $0.map { r in r.asExternalModel() } }
            .share()
            .eraseToAnyPublisher()
    }
    private func fetchLanguages(_ db: Database) throws -> [LanguageRecord] {
        try LanguageRecord.all().orderedByKey().fetchAll(db)
    }

    func getLanguageTranslations(_ key: String) -> LanguageTranslations? {
        try! reader.read {
            try fetchLanguageTranslations($0, key)
        }?.asExternalModel()
    }

    func streamLanguageTranslations(_ key: String) -> AnyPublisher<LanguageTranslations?, Error> {
        ValueObservation
            .tracking { try self.fetchLanguageTranslations($0, key) }
            .publisher(in: reader)
            .map { $0?.asExternalModel() }
            .share()
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
