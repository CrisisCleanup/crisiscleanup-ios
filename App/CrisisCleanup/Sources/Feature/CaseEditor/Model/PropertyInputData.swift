import Combine

class PropertyInputData: ObservableObject {
    @Published var residentName = ""
    @Published var phoneNumber = ""
    @Published var phoneNotes = ""
    @Published var phoneNumberSecondary = ""
    @Published var phoneNotesSecondary = ""
    @Published var email = ""
    @Published var autoContactFrequency = AutoContactFrequency.notOften

    @Published var residentNameError = ""
    @Published var phoneNumberError = ""
    @Published var emailError = ""

    func load(_ worksite: Worksite) {
        residentName = worksite.name
        phoneNumber = worksite.phone1
        phoneNotes = worksite.phone1Notes
        phoneNumberSecondary = worksite.phone2
        phoneNotesSecondary = worksite.phone2Notes
        email = worksite.email ?? ""
        autoContactFrequency = worksite.autoContactFrequency
    }

    func formatPhoneNumber(_ validator: InputValidator) {
        let result = validator.validatePhoneNumber(phoneNumber)
        if result.isValid {
            phoneNumber = result.formatted
        }
    }

    func formatPhoneNumberSecondary(_ validator: InputValidator) {
        let result = validator.validatePhoneNumber(phoneNumberSecondary)
        if result.isValid {
            phoneNumberSecondary = result.formatted
        }
    }

    func resetValidity() {
        residentNameError = ""
        phoneNumberError = ""
        emailError = ""
    }

    func validate(
        _ inputValidator: InputValidator,
        _ t: (String) -> String
    ) -> Bool {
        resetValidity()

        if residentName.isBlank {
            residentNameError = t("caseForm.name_required")
            return false
        }
        if phoneNumber.isBlank {
            phoneNumberError = t("caseForm.phone_required")
            return false
        }
        if !inputValidator.validatePhoneNumber(phoneNumber).isValid {
            phoneNumberError = t("info.invalid_phone_number")
            return false
        }
        if email.isNotBlank && !inputValidator.hasEmailAddress(email) {
            emailError = t("info.enter_valid_email")
            return false
        }

        return true
    }

    func updateCase(
        _ worksite: Worksite,
        _ inputValidator: InputValidator,
        _ t: (String) -> String
    ) -> Worksite? {
        if !validate(inputValidator, t) {
            return nil
        }

        return worksite.copy {
            $0.name = residentName.trim()
            $0.phone1 = phoneNumber.trim()
            $0.phone1Notes = phoneNotes.trim()
            $0.phone2 = phoneNumberSecondary.trim()
            $0.phone2Notes = phoneNotesSecondary.trim()
            $0.email = email.trim()
            $0.autoContactFrequencyT = autoContactFrequency.literal
        }
    }

    func getInvalidSection(
        _ inputValidator: InputValidator,
        _ t: (String) -> String
    ) -> InvalidWorksiteInfo {
        var focusElements = [CaseEditorElement]()
        var translationKeys = [String]()

        if residentName.isBlank {
            focusElements.append(.name)
            translationKeys.append("caseForm.name_required")
        }
        if phoneNumber.isBlank {
            focusElements.append(.phone)
            translationKeys.append("caseForm.phone_required")
        }
        if !inputValidator.validatePhoneNumber(phoneNumber).isValid {
            focusElements.append(.phone)
            translationKeys.append("info.invalid_phone_number")
        }
        if email.isNotBlank && !inputValidator.hasEmailAddress(email) {
            focusElements.append(.email)
            translationKeys.append("info.enter_valid_email")
        }

        let focusElement = focusElements.firstOrNil ?? .none
        let message = translationKeys
            .map(t)
            .joined(separator: "\n")
        return InvalidWorksiteInfo(focusElement, message)
    }
}
