import Combine
import Foundation

public protocol LanguageTranslationsRepository: KeyTranslator {
    var isLoading: Published<Bool>.Publisher { get }

    var supportedLanguages: Published<[Language]>.Publisher { get }

    var currentLanguage: Published<Language>.Publisher { get }

    func loadLanguages(_ force: Bool) async

    func setLanguage(_ key: String)
}

extension LanguageTranslationsRepository {
    func loadLanguages() async {
        await loadLanguages(false)
    }

    func setLanguage() {
        setLanguage("")
    }
}

class OfflineFirstLanguageTranslationsRepository: LanguageTranslationsRepository {
    @Published private var isLoadingStream = false
    lazy var isLoading = $isLoadingStream

    @Published private var supportedLanguagesStream: [Language] = []
    lazy var supportedLanguages = $supportedLanguagesStream

    @Published private var currentLanguageStream = EnglishLanguage
    lazy var currentLanguage = $currentLanguageStream

    @Published private var translationCountStream = 0
    lazy var translationCount = $translationCountStream

    private let dataSource: CrisisCleanupNetworkDataSource
    private let logger: AppLogger

    private var appPreferences: AppPreferences = AppPreferences()

    private var translationCache = Dictionary<String, String>()

    private var disposables = Set<AnyCancellable>()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        appPreferencesDataStore: AppPreferencesDataStore,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        logger = loggerFactory.getLogger("language-translations")

        appPreferencesDataStore.preferences
            .assign(to: \.appPreferences, on: self)
            .store(in: &disposables)
    }

    func loadLanguages(_ force: Bool) async {
        // TODO Rely on language count when database is ready
        if translationCache.count > 0 { return }

        isLoadingStream = true
        do {
            defer { isLoadingStream = false }

            let languageCount = 0

            if force || languageCount == 0 {
                try await pullLanguages()
            }

            if languageCount == 0 {
                try await pullTranslations(EnglishLanguage.key)
            }
            // TODO: Pull updated once database is saving results
        } catch {
            logger.logError(error)
        }
    }

    private func pullLanguages() async throws {
        let languages = try await dataSource.getLanguages()
        // TODO: Save to db
    }

    private func pullTranslations(_ key: String) async throws {
        if let translations = try await dataSource.getLanguageTranslations(key) {
            // TODO: Save to database when ready
            translationCache = translations.translations
        }
    }

    private func pullUpdatedTranslations(_ key: String) async throws {
        // TODO: Compare localizations updated since then pull
        try await pullTranslations(key)
    }

    private func pullUpdatedTranslations() async throws {
        try await pullLanguages()
        try await pullUpdatedTranslations(appPreferences.languageKey)
    }

    func setLanguage(_ key: String) {
        // TODO: Do
    }

    func translate(_ phraseKey: String) -> String? {
        // TODO: Do
        return nil
    }
}
