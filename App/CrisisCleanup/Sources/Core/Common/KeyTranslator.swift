import Combine
import SwiftUI

public protocol KeyTranslator {
    var translationCount: any Publisher<Int, Never> { get }

    func translate(_ phraseKey: String) -> String?

    func t(_ phraseKey: String) -> String
}

public protocol KeyAssetTranslator : KeyTranslator {
    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String
}

private class EmptyTranslator: KeyAssetTranslator {
    func t(_ phraseKey: String) -> String {
        translate(phraseKey) ?? phraseKey
    }

    let translationCount: any Publisher<Int, Never> = Just(0).eraseToAnyPublisher()

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
