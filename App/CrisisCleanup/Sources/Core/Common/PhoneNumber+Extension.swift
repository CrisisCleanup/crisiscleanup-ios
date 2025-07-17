import Foundation

public protocol PhoneNumberParser {
    func getPhoneNumbers(_ possiblePhoneNumbers: [String?]) -> [ParsedPhoneNumber]
}

class PhoneNumberRegexParser: PhoneNumberParser {
    private let noNumbersPattern = #/^\D+$/#

    private let isTenDigitNumberPattern = #/^\s*\d{10}\s*$/#
    private let isOneTenDigitNumberPattern = #/^\s*1\d{10}\s*$/#

    // TODO: Word boundary does not work when unicode is involved
    private let inParenthesisPattern = #/\((\d{3})\)/#
    private let leadingOnePattern = #/(?:^|\b)\+?1\s/#
    private let compact334DelimiterPattern = #/(?:^|\b)1?(\d{3})(.)(\d{3})\2(\d{4})(?:$|\b)/#
    private let compact334SpacePattern = #/(?:^|\b)1?(\d{3})\s+(\d{3})\s+(\d{4})(?:$|\b)/#
    private let digitDashDigitPattern = #/(\d)-(\d)/#
    private let digitEndParenthesisDigitPattern = #/(\d)\) (\d)/#
    private let compact37Pattern = #/(?:^|\b)1?(\d{3})[.-]?\s(\d{7})(?:$|\b)/#
    private let compact64Pattern = #/(?:^|\b)1?(\d{6})[.-]?\s(\d{4})(?:$|\b)/#
    private let leadingOnePostfixPattern = #/(?:^|\b)1(?:- )?(\d{10})(?:$|\b)/#
    private let nonNumericEndsPattern = #/^\D*\b(\d{10})\b\D*$/#
    private let repeatingNumbersPattern = #/\b(\d)\1{4,}\b/#
    private let shortWordsPattern = #/\b[a-zA-Z]{3,}\b/#

    private let digitSequencePattern = #/(?:^|\b|[\D\W])1?(\d{9,16})(?:$|\D+)/#
    private let separated37Pattern = #/(?:^|\b)(\d{3})[. -](\d{7})(?:$|\b)/#
    private let nonDigitPattern = #/\D/#

    private func exactTenDigits(_ s: String) -> String? {
        if s.isBlank {
            return ""
        }

        if isOneTenDigitNumberPattern.matches(s) {
            return s.trim().substring(1, s.count - 1)
        }

        if isTenDigitNumberPattern.matches(s) {
            return s.trim()
        }

        return nil
    }

    internal func parsePhoneNumbers(_ raw: String) -> ParsedPhoneNumber? {
        if raw.trim().count < 6 {
            return nil
        }

        func singleParsedNumber(_ result: String) -> ParsedPhoneNumber {
            return ParsedPhoneNumber(raw, [result.trim()])
        }

        if let exactDigits = exactTenDigits(raw) {
            return singleParsedNumber(exactDigits)
        }

        if noNumbersPattern.matches(raw) {
            return nil
        }

        let unparenthesized = raw.replacing(inParenthesisPattern) { $0.output.1 }
        let leadingOneTrimmed = unparenthesized.replacing(leadingOnePattern, with: "")
        let threeThreeFourUndelimited = leadingOneTrimmed.replacing(compact334DelimiterPattern) {
            let c = $0.output
            return " \(c.1)\(c.3)\(c.4) "
        }

        if let tenDigits = exactTenDigits(threeThreeFourUndelimited) {
            return singleParsedNumber(tenDigits)
        }

        let threeThreeFourUnspaced = threeThreeFourUndelimited.replacing(compact334SpacePattern) {
            let c = $0.output
            return " \(c.1)\(c.2)\(c.3) "
        }
        let dashesRemoved = threeThreeFourUnspaced.replacing(digitDashDigitPattern) {
            let c = $0.output
            return "\(c.1)\(c.2)"
        }
        let endParenthesisRemoved = dashesRemoved.replacing(digitEndParenthesisDigitPattern) {
            let c = $0.output
            return "\(c.1)\(c.2)"
        }

        if let tenDigits = exactTenDigits(endParenthesisRemoved) {
            return singleParsedNumber(tenDigits)
        }

        let threeSevenCompacted = endParenthesisRemoved.replacing(compact37Pattern) {
            let c = $0.output
            return " \(c.1)\(c.2) "
        }

        if let tenDigits = exactTenDigits(threeSevenCompacted) {
            return singleParsedNumber(tenDigits)
        }

        let sixFourCompacted = threeSevenCompacted.replacing(compact64Pattern) {
            let c = $0.output
            return " \(c.1)\(c.2) "
        }
        let onePopped = sixFourCompacted.replacing(leadingOnePostfixPattern) { $0.output.1 }
        let nonNumericEnds = onePopped.replacing(nonNumericEndsPattern) { $0.output.1 }

        if let tenDigits = exactTenDigits(nonNumericEnds) {
            return singleParsedNumber(tenDigits)
        }

        let repeatNumbersRemoved = nonNumericEnds.replacing(repeatingNumbersPattern, with: "")
        let noShortWords = repeatNumbersRemoved.replacing(shortWordsPattern, with: " ")

        let matches = noShortWords.matches(of: digitSequencePattern)
        if !matches.isEmpty {
            let matchResults = matches.map { $0.output.1 }
                .map { String($0) }
            if matchResults.count > 1 {
                return ParsedPhoneNumber(raw, matchResults)
            } else {
                return singleParsedNumber(matchResults.first!)
            }
        }

        let trimmedLength = noShortWords.trim().count
        if 10 <= trimmedLength,
           trimmedLength <= 15 {
            if trimmedLength <= 12 {
                let matches = noShortWords.matches(of: separated37Pattern)
                if matches.isNotEmpty {
                    let c = matches[0].output
                    return singleParsedNumber("\(c.1)\(c.2)")
                }
            }

            let onlyNumbers = noShortWords.replacing(nonDigitPattern, with: "")
            if 9 <= onlyNumbers.count,
               onlyNumbers.count <= 11 {
                return singleParsedNumber(onlyNumbers)
            }
        }

        return nil
    }

    func getPhoneNumbers(_ possiblePhoneNumbers: [String?]) -> [ParsedPhoneNumber] {
        possiblePhoneNumbers
            .filter { $0?.isNotBlank == true }
            .compactMap { $0 }
            .compactMap { parsePhoneNumbers($0) }
    }

    func searchablePhoneNumbers(_ phone1: String, phone2: String) -> String {
        getPhoneNumbers([phone1, phone2])
            .map { $0.parsedNumbers }
            .flatMap { $0 }
            .filter { $0.isNotBlank }
            .map {
                if $0.starts(with: "1"),
                   $0.count == 11 {
                    $0.substring(1, $0.count-1)
                } else {
                    $0
                }
            }
            .flatMap {
                if $0.count == 10 {
                    [$0, $0.substring(3, $0.count-1)]
                } else {
                    [$0]
                }
            }
            .sorted { (a, b) in
                if a.count == 10 {
                    return true
                }

                if b.count == 10 {
                    return false
                }

                let closestTo10 = abs(a.count - 10) - abs(b.count - 10)
                return closestTo10 <= 0

            }
            .joined(separator: " ")
    }
}

extension Regex {
    fileprivate func matches(_ s: String) -> Bool {
        do {
            if let _ = try firstMatch(in: s) {
                return true
            }
        } catch {}
        return false
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
        // TODO: Deduplicate while keeping order
        self.parsedNumbers = parsedNumbers
    }
}
