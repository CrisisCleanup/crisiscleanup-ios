import SwiftUI

enum UserInfoInputFieldKey: String, Identifiable {
    case firstName,
         lastName,
         title,
         phone,
         password,
         confirmPassword,
         languageKey

    var id: String { rawValue }
}

struct UserInfoInputData {
    var firstName: String = ""
    var lastName: String = ""
    var title: String = ""
    var phone: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var languageKey: String = ""

    var firstNameError: String = ""
    var lastNameError: String = ""
    var phoneError: String = ""
    var passwordError: String = ""
    var confirmPasswordError: String = ""
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

    @Binding var languageOptions: [String]

    @Binding var info: UserInfoInputData

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        VStack(alignment: .leading) {
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
                ForEach(languageOptions, id: \.self) { key in
                    Button(t.t(key)) {
                        info.languageKey = key
                    }
                }
            } label: {
                Group {
                    Text(t.t(info.languageKey.ifBlank { "languages.en-us" }))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .textFieldBorder()
            .padding(.bottom)
        }
    }
}
