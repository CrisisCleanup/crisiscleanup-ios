import XCTest
@testable import CrisisCleanup

final class PhoneNumberTests: XCTestCase {
    private var phoneNumberParser: PhoneNumberParser!

    override func setUp() async throws {
        phoneNumberParser = PhoneNumberRegexParser()
    }

    func testEmptyPhoneNumbers() {
        let actual = phoneNumberParser.getPhoneNumbers(["", "  "])
        XCTAssertEqual([], actual)
    }

    func testTenElevenDigitPhoneNumbers() {
        let actual = phoneNumberParser.getPhoneNumbers(["1234567890", "11234567890"])
        let expected = [
            ParsedPhoneNumber("1234567890", ["1234567890"]),
            ParsedPhoneNumber("11234567890", ["11234567890"]),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testCommonSpacedPhoneNumbers() {
        let actual = phoneNumberParser.getPhoneNumbers(["123 456 7890", "123 4567890"])
        let expected = [
            ParsedPhoneNumber("123 456 7890", ["1234567890"]),
            ParsedPhoneNumber("123 4567890", ["1234567890"]),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testDoublePhoneNumber() {
        let actual = phoneNumberParser.getPhoneNumbers(["1234567890dgk e*11234567890"])
        let expected = [
            ParsedPhoneNumber("1234567890dgk e*11234567890", ["1234567890", "11234567890"]),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testOnlyNumbers() {
        let actual = phoneNumberParser.getPhoneNumbers(["1-2/3a4.5-6:7890"])
        let expected = [
            ParsedPhoneNumber("1-2/3a4.5-6:7890", ["1234567890"]),
        ]
        XCTAssertEqual(expected, actual)
    }
}
