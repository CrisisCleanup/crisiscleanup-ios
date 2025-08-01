import PhoneNumberKit

public protocol InputValidator {
    func validateEmailAddress(_ emailAddress: String) -> Bool

    func validatePhoneNumber(
        _ value: String,
        regionCode: String,
    ) -> PhoneNumberValidation

    func hasEmailAddress(_ text: String) -> Bool
}

extension InputValidator {
    func validatePhoneNumber(_ value: String) -> PhoneNumberValidation {
        validatePhoneNumber(value, regionCode: "US")
    }
}

class CommonInputValidator: InputValidator {
    private let emailPattern = #/^[\w\d._%+-]+@[\w\d.-]+\.[\w]{2,64}$/#.ignoresCase()
    private let nonDigitPattern = #/\D/#
    private let commonEmailPattern = #/\b[^@]+@[^.]+\.[A-Za-z]{2,}\b/#

    let phoneUtil = PhoneNumberUtility()

    func validateEmailAddress(_ emailAddress: String) -> Bool {
        (try? emailPattern.wholeMatch(in: emailAddress)) != nil
    }

    func validatePhoneNumber(_ value: String, regionCode: String) -> PhoneNumberValidation {
        var validationError: Error? = nil
        do {
            var phoneNumber = value
            if !value.trim().starts(with: "+") {
                let digits = value.trim().replacing(nonDigitPattern, with: "")
                if digits.count != 10 {
                    phoneNumber = "+\(value)"
                }
            }
            // TODO: Use region from device if not already being used
            if phoneUtil.isValidPhoneNumber(phoneNumber) {
                let parsed = try phoneUtil.parse(phoneNumber)
                let isUsCountryCode = regionCode == "US" && parsed.countryCode == 1
                let format: PhoneNumberFormat = isUsCountryCode ? .national : .international
                let formatted = phoneUtil.format(parsed, toType: format)
                return PhoneNumberValidation(
                    true,
                    formatted,
                )
            }
        } catch {
            validationError = error
        }
        return PhoneNumberValidation(
            false,
            "",
            validationError,
        )
    }

    func hasEmailAddress(_ text: String) -> Bool {
        (try? commonEmailPattern.firstMatch(in: text)) != nil
    }
}

public struct  PhoneNumberValidation {
    let isValid: Bool
    let formatted: String
    let error: Error?

    init(
        _ isValid: Bool,
        _ formatted: String,
        _ error: Error? = nil
    ) {
        self.isValid = isValid
        self.formatted = formatted
        self.error = error
    }
}
