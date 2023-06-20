public protocol InputValidator {
    func validateEmailAddress(_ emailAddress: String) -> Bool
}

class CommonInputValidator: InputValidator {
    private let emailRegex = #/^[\w\d._%+-]+@[\w\d.-]+\.[\w]{2,64}$/#.ignoresCase()

    func validateEmailAddress(_ emailAddress: String) -> Bool {
        (try? emailRegex.wholeMatch(in: emailAddress)) != nil
    }
}
