import XCTest
@testable import CrisisCleanup

final class NetworkLanguageTests: XCTestCase {
    func testGetLanguages() throws {
        let result = Bundle(for: NetworkLanguageTests.self)
            .loadJson("getLanguages", NetworkLanguagesResult.self)

        let expected = NetworkLanguagesResult(
            errors: nil,
            results: [
                NetworkLanguageDescription("en-US", "English (United States)"),
                NetworkLanguageDescription("es-MX", "Spanish (Mexico)"),
                NetworkLanguageDescription("cs", "Czech")
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
