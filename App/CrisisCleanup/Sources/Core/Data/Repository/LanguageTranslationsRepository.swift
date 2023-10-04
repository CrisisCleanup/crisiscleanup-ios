import Combine
import Foundation

public protocol LanguageTranslationsRepository: KeyAssetTranslator {
    var isLoading: any Publisher<Bool, Never> { get }

    var supportedLanguages: any Publisher<[Language], Never> { get }

    var currentLanguage: any Publisher<Language, Never> { get }

    func loadLanguages(_ force: Bool) async

    func setLanguage(_ key: String)

    func setLanguageFromSystem()

    func getLanguageOptions() async -> [LanguageIdName]
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
    let isLoading: any Publisher<Bool, Never>
    private var isLoadingLanguagesSubject = CurrentValueSubject<Bool, Never>(false)
    private var isSettingLanguageSubject = CurrentValueSubject<Bool, Never>(false)

    let supportedLanguages: any Publisher<[Language], Never>
    let currentLanguage: any Publisher<Language, Never>

    private let dataSource: CrisisCleanupNetworkDataSource
    private let appPreferencesDataStore: AppPreferencesDataStore
    private let languageDao: LanguageDao
    private let logger: AppLogger

    private var appPreferences: AppPreferences = AppPreferences()

    private var translations = Dictionary<String, String>()
    private let statusRepository: WorkTypeStatusRepository

    private var setLanguageTask: Task<Void, Error>? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        dataSource: CrisisCleanupNetworkDataSource,
        appPreferencesDataStore: AppPreferencesDataStore,
        languageDao: LanguageDao,
        statusRepository: WorkTypeStatusRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.appPreferencesDataStore = appPreferencesDataStore
        self.languageDao = languageDao
        self.statusRepository = statusRepository
        logger = loggerFactory.getLogger("language-translations")

        isLoading = Publishers.CombineLatest(
            isLoadingLanguagesSubject,
            isSettingLanguageSubject)
        .map { (b0, b1) in b0 || b1 }

        supportedLanguages = languageDao.streamLanguages()
            .assertNoFailure()
            .map { languages in
                languages.isEmpty ? [EnglishLanguage] : languages
            }

        let languageData = appPreferencesDataStore.preferences
            .eraseToAnyPublisher()
            .map { languageDao.streamLanguageTranslations($0.languageKey) }
            .switchToLatest()
            .map { languageTranslations in
                let lookup = languageTranslations?.translations ?? [String:String]()
                let selectedLanguage = languageTranslations?.language ?? EnglishLanguage
                return (lookup, selectedLanguage)
            }
            .assertNoFailure()

        translationCount = languageData.map { (lookup, _) in
            lookup.count
        }

        currentLanguage = languageData.map { (_, language)  in
            language
        }

        appPreferencesDataStore.preferences
            .assign(to: \.appPreferences, on: self)
            .store(in: &disposables)

        languageData.sink { (lookup, _) in
            self.translations = lookup
        }
        .store(in: &disposables)
    }

    private func pullLanguages() async throws {
        let languageDescriptions = try await dataSource.getLanguages()
            .map { $0.asRecord() }
        try await languageDao.saveLanguages(languageDescriptions)
    }

    private func pullTranslations(_ key: String) async throws {
        let syncAt = Date()
        if let t = try await dataSource.getLanguageTranslations(key) {
            try await languageDao.upsertLanguageTranslation(t.asRecord(syncAt))
        }
    }

    func loadLanguages(_ force: Bool) async {
        isLoadingLanguagesSubject.value = true
        do {
            defer { isLoadingLanguagesSubject.value = false }

            let languageCount = languageDao.getLanguageCount()

            if force || languageCount == 0 {
                try await pullLanguages()
            }

            if languageCount == 0 {
                try await pullTranslations(EnglishLanguage.key)
            } else {
                try await pullUpdatedTranslations()
            }

            setLanguageFromSystem()
        } catch {
            logger.logError(error)
        }
    }

    func setLanguageFromSystem() {
        if let systemLocale = NSLocale.preferredLanguages.first {
            setLanguage(systemLocale)
        }
    }

    private func pullUpdatedTranslations() async throws {
        try await pullUpdatedTranslations(appPreferences.languageKey)
    }

    private func pullUpdatedTranslations(_ key: String) async throws {
        if let t = languageDao.getLanguageTranslations(key) {
            let localizationUpdateCount = try await dataSource.getLocalizationCount(t.syncedAt)
            if localizationUpdateCount?.count ?? 0 > 0 {
                try await pullLanguages()
                try await pullTranslations(key)
            }
        }
    }

    func setLanguage(_ key: String) {
        setLanguageTask?.cancel()
        setLanguageTask = Task {
            isSettingLanguageSubject.value = true
            do {
                defer { isSettingLanguageSubject.value = false }

                let languages = try await supportedLanguages.eraseToAnyPublisher().asyncFirst()
                let languagesSet = Set(languages.map { $0.key })
                let languageKey = {
                    if languagesSet.contains(key) {
                        return key
                    }
                    if key.contains(where: { $0 == "-" }) {
                        let designator = String(key.split(separator: "-")[0])
                        if languagesSet.contains(designator) {
                            return designator
                        }
                    }
                    return EnglishLanguage.key
                }()

                try await pullUpdatedTranslations(languageKey)

                try Task.checkCancellation()

                appPreferencesDataStore.setLanguageKey(languageKey)
            } catch {
                logger.logError(error)
            }
        }
    }

    func getLanguageOptions() async -> [LanguageIdName] {
        do {
            return try await dataSource.getLanguages().map { LanguageIdName($0.id, $0.name) }
        } catch {
            logger.logError(error)
        }

        return [LanguageIdName]()
    }

    // MARK: - KeyAssetTranslator

    let translationCount: any Publisher<Int, Never>

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        translate(phraseKey) ?? (fallbackAssetKey.isBlank ? phraseKey : fallbackAssetKey.localizedString)
    }

    func translate(_ phraseKey: String) -> String? {
        if let translated = translations[phraseKey] {
            return translated
        }
        if let statusTranslated = statusRepository.translateStatus(phraseKey) {
            return statusTranslated.contains(phraseKey) == true ? translations[statusTranslated] : statusTranslated
        }
        return nil
    }

    func t(_ phraseKey: String) -> String {
        translate(phraseKey) ?? phraseKey
    }
}
