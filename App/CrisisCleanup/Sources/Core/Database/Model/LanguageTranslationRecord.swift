import Foundation
import GRDB

struct LanguageTranslationRecord: Identifiable, Equatable {
    let key: String
    let name: String
    let translationJson: String?
    let syncedAt: Date?

    var id: String { key }

    func asExternalModel() -> LanguageTranslations {
        var translations = [String: String]()
        if let json = translationJson {
            if json.isNotBlank {
                let jsonDecoder = JsonDecoderFactory().decoder()
                do {
                    translations = try jsonDecoder.decode([String: String].self, from: json.data(using: .utf8)!)
                } catch {
                    // TODO: Log error proper
                    print("Language decode error \(error)")
                }
            }
        }
        return LanguageTranslations(
            language: Language(key, name),
            translations: translations,
            syncedAt: syncedAt ?? Date(timeIntervalSince1970: 0)
        )
    }
}

extension LanguageTranslationRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "languageTranslation"

    fileprivate enum Columns: String, ColumnExpression {
        case key,
             name,
             translationJson,
             syncedAt
    }
}

struct LanguageRecord: Identifiable, Equatable {
    let key: String
    let name: String

    var id: String { key }

    func asExternalModel() -> Language { Language(key, name) }
}

extension LanguageRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "languageTranslation"
    static var databaseSelection: [any SQLSelectable] = [Columns.key, Columns.name]

    fileprivate enum Columns: String, ColumnExpression {
        case key, name
    }
}

extension DerivableRequest<LanguageRecord> {
    func orderedByKey() -> Self {
        order(LanguageRecord.Columns.key.asc)
    }
}
