import Foundation

public protocol PhoneNumberParser {
    func getPhoneNumbers(_ possiblePhoneNumbers: [String?]) -> [ParsedPhoneNumber]
}

class PhoneNumberRegexParser: PhoneNumberParser {
    private let bracketsDashRegex = #/[()-]/#
    private let letterRegex = #/[a-zA-Z]/#
    private let twoPlusSpacesRegex = #/\s{2,}/#
    private let nonNumberRegex = #/\D/#

    private let straightDigitsRegex = #/^\d{10,11}$/#
    private let threeThreeFourDigitsRegex = #/^\d{3} \d{3} \d{4}$/#
    private let areaCodeNumberRegex = #/^\d{3} \d{7}$/#
    private let twoPhoneNumbersRegex = #/^(\d{10,11})\D+(\d{10,11})$/#

    func getPhoneNumbers(_ possiblePhoneNumbers: [String?]) -> [ParsedPhoneNumber] {
        possiblePhoneNumbers
            .filter { $0?.isNotBlank == true }
            .map { $0! }
            .map { phoneIn in
                let filtered = phoneIn.trim()
                let cleaned = filtered.replacing(bracketsDashRegex, with: "")
                    .replacing(letterRegex, with: " ")
                    .replacing(twoPlusSpacesRegex, with: "  ")
                    .trim()

                if cleaned.isBlank {
                    return ParsedPhoneNumber(phoneIn, [])
                }

                do {
                    if let _ = try straightDigitsRegex.firstMatch(in: cleaned) {
                        return ParsedPhoneNumber(phoneIn, [cleaned])
                    }

                    if try threeThreeFourDigitsRegex.firstMatch(in: cleaned) != nil ||
                        areaCodeNumberRegex.firstMatch(in: cleaned) != nil {
                        let parsedNumber = cleaned.replacingOccurrences(of: " ", with: "")
                        return ParsedPhoneNumber(phoneIn, [parsedNumber])
                    }

                    if let match = try twoPhoneNumbersRegex.wholeMatch(in: cleaned) {
                        let parsedNumbers = [String(match.output.1), String(match.output.2)]
                        return ParsedPhoneNumber(phoneIn, parsedNumbers)
                    }

                    let onlyNumbers = cleaned.replacing(nonNumberRegex, with: "")
                    if let _ = try straightDigitsRegex.firstMatch(in: onlyNumbers) {
                        return ParsedPhoneNumber(phoneIn, [onlyNumbers])
                    }
                } catch {}

                return ParsedPhoneNumber(phoneIn, [])
            }
    }
}

public struct ParsedPhoneNumber: Equatable {
    let source: String
    let parsedNumbers: [String]

    init(
        _ source: String,
        _ parsedNumbers: [String]
    ) {
        self.source = source
        self.parsedNumbers = Array(Set(parsedNumbers))
    }
}
