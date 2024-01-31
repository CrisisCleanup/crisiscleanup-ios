import XCTest
@testable import CrisisCleanup

final class NetworkLanguageTests: XCTestCase {
    func testGetLanguages() throws {
        let result = Bundle(for: NetworkLanguageTests.self)
            .loadJson("getLanguages", NetworkLanguagesResult.self)

        let expected = NetworkLanguagesResult(
            errors: nil,
            results: [
                NetworkLanguageDescription(id: 2, subtag: "en-US", name: "English (United States)"),
                NetworkLanguageDescription(id: 7, subtag: "es-MX", name: "Spanish (Mexico)"),
                NetworkLanguageDescription(id: 8, subtag: "cs", name: "Czech")
            ]
        )
        XCTAssertEqual(expected, result)
    }

    func testGetTranslations() throws {
        let result = Bundle(for: NetworkAuthTests.self)
            .loadJson("getLanguageTranslation", NetworkLanguageTranslation.self)

        XCTAssertEqual("en-US", result.subtag)
        XCTAssertEqual("English (United States)", result.name)
        XCTAssertEqual(11, result.translations.count)
    }
}
