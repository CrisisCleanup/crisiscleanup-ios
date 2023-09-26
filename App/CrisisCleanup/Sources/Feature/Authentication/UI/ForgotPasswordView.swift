import SwiftUI

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
