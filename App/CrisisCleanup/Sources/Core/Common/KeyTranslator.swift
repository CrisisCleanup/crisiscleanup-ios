import Combine
import SwiftUI

public protocol KeyTranslator {
    var translationCount: Published<Int>.Publisher { get }

    func translate(_ phraseKey: String) -> String?

    func callAsFunction(_ phraseKey: String) -> String
}

public protocol KeyAssetTranslator : KeyTranslator {
    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String
}

private class EmptyTranslator: KeyAssetTranslator {
    func callAsFunction(_ phraseKey: String) -> String {
        translate(phraseKey) ?? phraseKey
    }

    @Published private var translationCountStream = 0
    lazy private(set) var translationCount = $translationCountStream

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        fallbackAssetKey.localizedString
    }

    func translate(_ phraseKey: String) -> String? {
        let translated = translate(phraseKey, "")
        return translated == phraseKey ? nil : translated
    }
}
private let emptyTranslator = EmptyTranslator()

private struct TranslatorKey: EnvironmentKey {
    static var defaultValue: KeyAssetTranslator { emptyTranslator }
}

extension EnvironmentValues {
    var translator: KeyAssetTranslator {
        get { self[TranslatorKey.self] }
        set { self[TranslatorKey.self] = newValue }
    }
}
