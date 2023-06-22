import Combine
import Foundation

public protocol LanguageTranslationsRepository: KeyAssetTranslator {
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
    private var isLoadingLanguages = CurrentValueSubject<Bool, Never>(false)
    private var isSettingLanguage = CurrentValueSubject<Bool, Never>(false)

    @Published private var isLoadingStream = false
    lazy private(set) var isLoading = $isLoadingStream

    @Published private var supportedLanguagesStream: [Language] = [EnglishLanguage]
    lazy private(set) var supportedLanguages = $supportedLanguagesStream

    @Published private var currentLanguageStream = EnglishLanguage
    lazy private(set) var currentLanguage = $currentLanguageStream

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

        appPreferencesDataStore.preferences
            .assign(to: \.appPreferences, on: self)
            .store(in: &disposables)

        isLoadingLanguages.combineLatest(isSettingLanguage)
            .map { (b0, b1) in b0 || b1 }
            .assign(to: &isLoading)

        languageDao.streamLanguages()
            .sink { completion in
            } receiveValue: { languages in
                self.supportedLanguagesStream = languages.isEmpty ? [EnglishLanguage] : languages
            }
            .store(in: &disposables)

        appPreferencesDataStore.preferences
            .eraseToAnyPublisher()
            .map { languageDao.streamLanguageTranslations($0.languageKey) }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { completion in
            } receiveValue: { languageTranslations in
                let lookup = languageTranslations?.translations ?? [String:String]()
                self.translations = lookup
                self.currentLanguageStream = languageTranslations?.language ?? EnglishLanguage
                self.translationCountStream = lookup.count
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
        isLoadingLanguages.value = true
        do {
            defer { isLoadingLanguages.value = false }

            let languageCount = languageDao.getLanguageCount()

            if force || languageCount == 0 {
                try await pullLanguages()
            }

            if languageCount == 0 {
                try await pullTranslations(EnglishLanguage.key)
            } else {
                try await pullUpdatedTranslations()
            }
        } catch {
            logger.logError(error)
        }
    }

    private func pullUpdatedTranslations() async throws {
        try await pullUpdatedTranslations(appPreferences.languageKey)
    }

    private func pullUpdatedTranslations(_ key: String) async throws {
        if let t = languageDao.getLanguageTranslations(key) {
            let localizationUpdateCount = try await dataSource.getLocalizationCount(after: t.syncedAt)
            if localizationUpdateCount?.count ?? 0 > 0 {
                try await pullLanguages()
                try await pullTranslations(key)
            }
        }
    }

    func setLanguage(_ key: String) {
        setLanguageTask?.cancel()
        setLanguageTask = Task {
            isSettingLanguage.value = true
            do {
                defer { isSettingLanguage.value = false }

                try await pullUpdatedTranslations(key)

                try Task.checkCancellation()

                appPreferencesDataStore.setLanguageKey(key)
            } catch {
                logger.logError(error)
            }
        }
    }

    // MARK: - KeyAssetTranslator

    @Published private var translationCountStream = 0
    lazy private(set) var translationCount = $translationCountStream

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        translate(phraseKey) ?? (fallbackAssetKey.isBlank ? phraseKey : fallbackAssetKey.localizedString)
    }

    func translate(_ phraseKey: String) -> String? {
        translations[phraseKey] ?? statusRepository.translateStatus(phraseKey)
    }

    func callAsFunction(_ phraseKey: String) -> String {
        translate(phraseKey) ?? phraseKey
    }
}
