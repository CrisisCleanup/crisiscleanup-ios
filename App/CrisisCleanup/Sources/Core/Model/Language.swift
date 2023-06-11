import Foundation

public struct Language {
    let key: String
    let displayName: String

    init(
        _ key: String,
        _ displayName: String
    ) {
        self.key = key
        self.displayName = displayName
    }
}

public struct LanguageTranslations {
    let language: Language
    let translations: [String: String]
    let syncedAt: Date
}

let EnglishLanguage = Language("en-US", "English (United States)")
