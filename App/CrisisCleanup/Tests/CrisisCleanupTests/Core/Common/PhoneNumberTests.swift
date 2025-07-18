import XCTest
@testable import CrisisCleanup

final class PhoneNumberTests: XCTestCase {
    private var phoneNumberParser: RegexPhoneNumberParser!

    override func setUp() async throws {
        phoneNumberParser = RegexPhoneNumberParser()
    }

    func testInvalidPhoneNumbers() {
        let inputs = [
            "",
            "   ",
            " 12345 ",
            " no numbers",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertNil(actual)
        }
    }

    func testTenDigitNumberExactly() {
        let inputs = [
            "1234567890",
            "  1234567890",
            "1234567890   ",
            "  1234567890  ",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(["1234567890"], actual)
        }
    }

    func testNoCompaction() {
        let inputs = [
            " (234)5678901 ",
            "(234)5678901",
            " 1(234)5678901",
            "12345678901 ",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(["2345678901"], actual)
        }
    }

    func testCompact334() {
        let inputs = [
            "234 567 8901",
            "234-567-8901",
            "234.567.8901",
            "1234 567 8901",
            "1234-567-8901",
            "1234.567.8901",
            "1234.567.8901",
            "(234).567.8901",
            "1(234).567.8901",
            "234 567  8901 ",
            " 234  567 8901",
            " 234  567  8901 ",
            "1234  567  8901 ",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(["2345678901"], actual)
        }
    }

    func testDashParenthesis() {
        let inputs = [
            "234567-8901",
            "234-5678901",
            "234) 567-8901",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(["2345678901"], actual)
        }
    }

    func testNonNumeric3764() {
        let inputs = [
            "234 5678901",
            "1234 5678901",
            "something 1234 5678901-cell",
            "+234 5678901 (air)",
            "2345678901 a number",
            "a 1234 5678901 b",
            "234567 8901",
            "something 234567 8901-cell",
            "a 234567 8901 b",
            "1234567 8901",
            "12345678901 for anyone",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(["2345678901"], actual)
        }
    }

    func testPossibleMultiple() {
        let inputs: [String: [String]] = [
            "23456789012": ["23456789012"],
            "1\u{202A}2345678901": ["2345678901"],
            "2345678901 or 3456789012": [
                "2345678901",
                "3456789012",
            ],
            "234567890": ["234567890"],
            "234567890-": ["234567890"],
            "2345678901  . 4282 M-F": ["2345678901"],
            "2345678901 / 3456789012": [
                "2345678901",
                "3456789012",
            ],
            "1.7068339198": ["7068339198"],
            "(23456789012": ["23456789012"],
            "18002345678901": ["8002345678901"],
            "2345678901   1st": ["2345678901"],
            "2345678901             9  0": ["2345678901"],
            "2345678901 (  be 3456789012)": [
                "2345678901",
                "3456789012",
            ],
            "2345678901/3456789012": [
                "2345678901",
                "3456789012",
            ],
            "  2345678901 or      3456789012 ": [
                "2345678901",
                "3456789012",
            ],
            "2345678901/ 3456789012 ( )": [
                "2345678901",
                "3456789012",
            ],
            "2345678901/3456789012/4567891234": [
                "2345678901",
                "3456789012",
                "4567891234",
            ],
            "2345678901, 3456789012, 4567891234 \n": [
                "2345678901",
                "3456789012",
                "4567891234",
            ],
            "1234567890r9 ": ["234567890"],
            "2345678901 x558   ": ["2345678901"],
        ]

        for (input, expected) in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(expected, actual, "Failed for input: \(input)")
        }
    }

    func testDotDelimited11() {
        let inputs = [
            "234.5678901",
            "(234.5678901",
        ]

        for input in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers
            XCTAssertEqual(["2345678901"], actual)
        }
    }

    func testMostlyNumbers() {
        let inputs: [String: String] = [
            "234 567- 8901-  ": "2345678901",
            "1234*5678901": "12345678901",
            "123 4567 8901": "12345678901",
            "123456 78901": "12345678901",
        ]

        for (input, expected) in inputs {
            let actual = phoneNumberParser.parsePhoneNumbers(input)?.parsedNumbers.first
            XCTAssertEqual(expected, actual, "Failed for input: \(input)")
        }
    }
}
