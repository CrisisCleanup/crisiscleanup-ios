import Combine

public protocol KeyTranslator {
    var translationCount: Published<Int>.Publisher { get }

    func translate(phraseKey: String) -> String?
}

public protocol KeyAssetTranslator : KeyTranslator {
    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String

    // TODO: Can a variation of this work as expected when implemented by a class?
//    func callAsFunction(phraseKey: String, fallbackAssetKey: String) -> String
}
