import SwiftUI

struct UserInfoInputData {
    var emailAddress: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var title: String = ""
    var phone: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var language: LanguageIdName = LanguageIdName(0, "")

    var emailAddressError: String = ""
    var firstNameError: String = ""
    var lastNameError: String = ""
    var phoneError: String = ""
    var passwordError: String = ""
    var confirmPasswordError: String = ""

    mutating func clearErrors() {
        emailAddressError = ""
        firstNameError = ""
        lastNameError = ""
        phoneError = ""
        passwordError = ""
        confirmPasswordError = ""
    }

    mutating func validateInput(
        _ inputValidator: InputValidator,
        _ translator: KeyTranslator
    ) -> [TextInputFocused] {
        var errorFocuses = [TextInputFocused]()

        if !inputValidator.validateEmailAddress(emailAddress) {
            emailAddressError = translator.t("invitationSignup.email_error")
            errorFocuses.append(.userEmailAddress)
        }

        if firstName.isBlank {
            firstNameError = translator.t("~~First name is required.")
            errorFocuses.append(.userFirstName)
        }

        if lastName.isBlank {
            lastNameError = translator.t("~~Last name is required.")
            errorFocuses.append(.userLastName)
        }

        if password.trim().count < 8 {
            passwordError = translator.t("invitationSignup.password_length_error")
            errorFocuses.append(.userPassword)
        }

        if password != confirmPassword {
            confirmPasswordError = translator.t("invitationSignup.password_match_error")
            errorFocuses.append(.userConfirmPassword)
        }

        if phone.isBlank {
            phoneError = translator.t("invitationSignup.mobile_error")
            errorFocuses.append(.userPhone)
        }

        // Language defaults to US English

        return errorFocuses
    }
}

private struct UserInfoErrorText: View {
    let message: String

    var body: some View {
        if message.isNotBlank {
            Text(message)
                .foregroundColor(appTheme.colors.primaryRedColor)
        }
    }
}

struct UserInfoInputView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var languageOptions: [LanguageIdName]

    @Binding var info: UserInfoInputData

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                UserInfoErrorText(message: info.emailAddressError)
                TextField(t.t("requestAccess.your_email"), text: $info.emailAddress)
                    .textFieldBorder()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused(focusState, equals: TextInputFocused.userEmailAddress)
                    .onSubmit { focusState.wrappedValue = .userFirstName }
                    .padding(.bottom)
            }

            Group {
                UserInfoErrorText(message: info.firstNameError)
                TextField(t.t("invitationSignup.first_name_placeholder"), text: $info.firstName)
                    .textFieldBorder()
                    .autocapitalization(.words)
                    .focused(focusState, equals: TextInputFocused.userFirstName)
                    .onSubmit { focusState.wrappedValue = .userLastName }
                    .padding(.bottom)
            }

            Group {
                UserInfoErrorText(message: info.lastNameError)
                TextField(t.t("invitationSignup.last_name_placeholder"), text: $info.lastName)
                    .textFieldBorder()
                    .autocapitalization(.words)
                    .focused(focusState, equals: TextInputFocused.userLastName)
                    .onSubmit { focusState.wrappedValue = .userTitle }
                    .padding(.bottom)
            }

            TextField(t.t("invitationSignup.title_placeholder"), text: $info.title)
                .textFieldBorder()
                .autocapitalization(.words)
                .focused(focusState, equals: TextInputFocused.userTitle)
                .onSubmit { focusState.wrappedValue = .userPhone }
                .padding(.bottom)

            Group {
                UserInfoErrorText(message: info.phoneError)
                TextField(t.t("invitationSignup.mobile_placeholder"), text: $info.phone)
                    .textFieldBorder()
                    .focused(focusState, equals: TextInputFocused.userPhone)
                    .onSubmit { focusState.wrappedValue = .userPassword }
                    .padding(.bottom)
            }

            Group {
                UserInfoErrorText(message: info.passwordError)
                ToggleSecureTextField(
                    t.t("invitationSignup.pw1_placeholder"),
                    text: $info.password,
                    focusState: focusState,
                    focusedKey: .userPassword
                ) {
                    focusState.wrappedValue = .userConfirmPassword
                }
                .padding(.bottom)

                UserInfoErrorText(message: info.confirmPasswordError)
                ToggleSecureTextField(
                    t.t("invitationSignup.pw2_placeholder"),
                    text: $info.confirmPassword,
                    focusState: focusState,
                    focusedKey: .userConfirmPassword
                )
                .padding(.bottom)
            }

            Menu {
                ForEach(languageOptions, id: \.id) { language in
                    Button(t.t(language.name)) {
                        info.language = language
                    }
                }
            } label: {
                Group {
                    Text(t.t(info.language.name.ifBlank { "languages.en-us" }))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundColor(.black)
            }
            .padding(.bottom)
        }
    }
}
