public struct NetworkLanguagesResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let results: [NetworkLanguageDescription]
}

public struct NetworkLanguageDescription: Codable, Equatable {
    let subtag: String
    let name: String
    enum CodingKeys: String, CodingKey {
        case subtag
        case name = "name_t"
    }

    init(
        _ subtag: String,
        _ name: String
    ) {
        self.subtag = subtag
        self.name = name
    }
}

public struct NetworkLanguageTranslationResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let translation: NetworkLanguageTranslation?
}

public struct NetworkLanguageTranslation: Codable, Equatable {
    let subtag: String
    let name: String
    let translations: [String: String]
    enum CodingKeys: String, CodingKey {
        case subtag
        case name = "name_t"
        case translations
    }
}
