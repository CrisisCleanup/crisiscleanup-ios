import Combine
import SwiftUI

public protocol KeyTranslator {
    var translationCount: Published<Int>.Publisher { get }

    func translate(_ phraseKey: String) -> String?
}

public protocol KeyAssetTranslator : KeyTranslator {
    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String

    // TODO: Does this work? If not delete.
    func callAsFunction(_ phraseKey: String, _ fallbackAssetKey: String) -> String
}

fileprivate class EmptyTranslator: KeyAssetTranslator {
    func callAsFunction(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        return translate(phraseKey, fallbackAssetKey)
    }

    @Published private var translationCountStream = 0
    lazy var translationCount = $translationCountStream

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        return fallbackAssetKey.localizedString
    }

    func translate(_ phraseKey: String) -> String? {
        let translated = translate(phraseKey, "")
        return translated == phraseKey ? nil : translated
    }
}

fileprivate let emptyTranslator = EmptyTranslator()

private struct TranslatorKey: EnvironmentKey {
    static var defaultValue: KeyAssetTranslator { emptyTranslator }
}

extension EnvironmentValues {
    var translator: KeyAssetTranslator {
        get { self[TranslatorKey.self] }
        set { self[TranslatorKey.self] = newValue }
    }
}