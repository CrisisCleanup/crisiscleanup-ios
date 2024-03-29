import Foundation

extension NetworkLanguageDescription {
    func asRecord() -> LanguageTranslationRecord {
        LanguageTranslationRecord(
            key: subtag,
            name: name,
            translationJson: nil,
            syncedAt: nil
        )
    }
}

extension NetworkLanguageTranslation {
    func asRecord(_ syncedAt: Date) -> LanguageTranslationRecord {
        let json = try? JSONEncoder().encodeToString(translations.filter { $0.value != nil })
        return LanguageTranslationRecord(
            key: subtag,
            name: name,
            translationJson: json,
            syncedAt: syncedAt
        )
    }
}
