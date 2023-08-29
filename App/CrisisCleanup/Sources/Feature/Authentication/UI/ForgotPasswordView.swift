import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @State var tempString = ""
    @State var resetPressed = false

    @State var tempError = true

    var body: some View {

        if(true) {
            VStack(alignment: .leading) {
                if(resetPressed) {
                    Text(t.t("resetPassword.email_arrive_soon_check_junk"))
                        .fontHeader3()
                        .onTapGesture {
                            resetPressed.toggle()
                        }
                } else {

                    Text(t.t("resetPassword.forgot_your_password_or_reset"))
                        .fontHeader3()
                        .padding(.bottom)

                    Text(t.t("resetPassword.enter_email_for_reset_instructions"))
                        .padding(.bottom)

                    if(tempError) {
                        Text(t.t("info.enter_valid_email"))
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .padding(.top)
                    }

                    // use inputValidator
                    TextField(t.t("loginForm.email_placeholder"), text: $tempString)
                        .textFieldBorder()
                        .padding(.bottom)


                    Button {
                        // TODO: reset password
                        resetPressed.toggle()
                    } label: {
                        Text("~~Reset Password")
                    }
                    .stylePrimary()
                    .padding(.bottom)

                    MagicLinkView()

                }

                Spacer()
            }
            .padding(.horizontal)
        } else {
            ResetPasswordView()
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @State var password = ""
    @State var confirmPassword = ""

    var error = true

    var body: some View {
        VStack(alignment: .leading) {
            Text(t.t("resetPassword.enter_new_password"))
                .fontHeader3()

            if(error) {
                Text("t.tplace error message here")
                    .foregroundColor(appTheme.colors.primaryRedColor)
                    .padding(.top)
            }

            ToggleSecureTextField(t.t("resetPassword.password"), text: $password)
                .padding(.top)

            ToggleSecureTextField(t.t("resetPassword.confirm_password"), text: $confirmPassword)
                .padding(.vertical)

            Button {
                // TODO: reset password
            } label : {
                Text(t.t("actions.reset"))
            }
            .stylePrimary()

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct MagicLinkView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @State var magicPressed = false
    @State var tempString = ""

    @State var tempError = true

    var body: some View {
        if (magicPressed) {
            Text(t.t("magicLink.magic_link_sent"))
                .fontHeader3()
                .onTapGesture {
                    magicPressed.toggle()
                }
        } else {
            Text(t.t("actions.request_magic_link"))
                .fontHeader3()
                .padding(.vertical)

            Text(t.t("magicLink.magic_link_description"))
                .padding(.bottom)

            if(tempError) {
                Text(t.t("info.enter_valid_email"))
                    .foregroundColor(appTheme.colors.primaryRedColor)
                    .padding(.top)
            }

            TextField(t.t("loginForm.email_placeholder"), text: $tempString)
                .textFieldBorder()
                .padding(.bottom)

            Button {
                // TODO: magic link
                magicPressed.toggle()
            } label: {
                Text(t.t("actions.submit"))
            }
            .stylePrimary()
        }
    }
}
