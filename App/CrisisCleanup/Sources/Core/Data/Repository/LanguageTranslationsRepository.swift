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
