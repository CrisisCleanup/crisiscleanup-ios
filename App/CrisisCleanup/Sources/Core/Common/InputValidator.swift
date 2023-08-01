public protocol InputValidator {
    func validateEmailAddress(_ emailAddress: String) -> Bool

    func validatePhoneNumber(
        _ value: String,
        allowSpaces: Bool
    ) -> Bool

    func hasEmailAddress(_ text: String) -> Bool
}

extension InputValidator {
    func validatePhoneNumber(_ value: String) -> Bool {
        validatePhoneNumber(value, allowSpaces: true)
    }
}

class CommonInputValidator: InputValidator {
    private let emailRegex = #/^[\w\d._%+-]+@[\w\d.-]+\.[\w]{2,64}$/#.ignoresCase()
    private let phoneNumbersRegex = #/^\+?[\d-]+$/#
    private let phoneNumbersAndSpacesRegex = #/^\+?[\d\s-]+$/#
    private let commonEmailRegex = #/\b[^@]+@[^.]+\.[A-Za-z]{2,}\b/#

    func validateEmailAddress(_ emailAddress: String) -> Bool {
        (try? emailRegex.wholeMatch(in: emailAddress)) != nil
    }

    func validatePhoneNumber(_ value: String, allowSpaces: Bool) -> Bool {
        allowSpaces ? (try? phoneNumbersAndSpacesRegex.wholeMatch(in: value)) != nil
        : (try? phoneNumbersRegex.wholeMatch(in: value)) != nil
    }

    func hasEmailAddress(_ text: String) -> Bool {
        (try? commonEmailRegex.firstMatch(in: text)) != nil
    }
}
