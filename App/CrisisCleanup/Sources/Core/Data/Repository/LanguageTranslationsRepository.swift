import Combine

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

    private var translationCache = Dictionary<String, String>()

    init() {

    }

    func loadLanguages(_ force: Bool) async {
        // TODO: Do
    }

    func setLanguage(_ key: String) {
        // TODO: Do
    }

    func translate(_ phraseKey: String) -> String? {
        // TODO: Do
        return nil
    }
}
