import Combine

class PropertyInputData: ObservableObject {
    @Published var residentName = ""
    @Published var phoneNumber = ""
    @Published var phoneNumberSecondary = ""
    @Published var email = ""
    @Published var autoContactFrequency = AutoContactFrequency.notOften

    @Published var residentNameError = ""
    @Published var phoneNumberError = ""
    @Published var emailError = ""

    func load(_ worksite: Worksite) {
        residentName = worksite.name
        phoneNumber = worksite.phone1
        phoneNumberSecondary = worksite.phone2
        email = worksite.email ?? ""
        autoContactFrequency = worksite.autoContactFrequency
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
        if email.isNotBlank && !inputValidator.hasEmailAddress(email) {
            emailError = t("info.enter_valid_email")
            return false
        }

        return true
    }

    func getUserErrorMessage(
        _ inputValidator: InputValidator,
        _ t: (String) -> String
    ) -> String {
        var messages = [String]()
        if residentName.isBlank {
            messages.append(t("caseForm.name_required"))
        }
        if phoneNumber.isBlank {
            messages.append(t("caseForm.phone_required"))
        }
        if email.isNotBlank && !inputValidator.hasEmailAddress(email) {
            messages.append(t("info.enter_valid_email"))
        }

        return messages.joined(separator: "\n")
    }
}
