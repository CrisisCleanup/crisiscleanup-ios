import SwiftUI

struct AuthenticateView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.translator) var t: KeyAssetTranslator
    @ObservedObject var viewModel: AuthenticateViewModel

    var body: some View {
        let dismissScreen = { presentationMode.wrappedValue.dismiss() }
        if viewModel.viewData.isTokenInvalid {
            LoginView(
                viewModel: viewModel,
                dismissScreen: dismissScreen,
                emailAddress: viewModel.viewData.accountData.emailAddress
            )
        } else {
            let logout = { viewModel.logout() }
            LogoutView(
                viewModel: viewModel,
                logout: logout,
                dismissScreen: dismissScreen
            )
        }
    }
}

struct LoginView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @ObservedObject var viewModel: AuthenticateViewModel
    var dismissScreen: () -> ()

    @State var emailAddress: String = ""
    @State var password: String = ""
    @FocusState var emailHasFocus: Bool
    @FocusState var passwordHasFocus: Bool

    func authenticate() {
        viewModel.authenticate(emailAddress, password)
    }

    var body: some View {
        let disabled = viewModel.isAuthenticating
        let buttonStyle = PrimaryButtonStyle(disabled)

        VStack {
            let errorMessage = $viewModel.errorMessage.wrappedValue
            if !errorMessage.isBlank {
                Text(errorMessage)
                    .padding([.vertical])
            }

            TextField(t.translate("loginForm.email_placeholder", "Email hint"), text: $emailAddress)
                .textFieldBorder()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding([.vertical])
                .disableAutocorrection(true)
                .focused($emailHasFocus)
                .disabled(disabled)
                .onChange(of: viewModel.emailHasFocus) { emailHasFocus = $0 }
                .onSubmit { authenticate() }
                .onAppear { emailHasFocus = true }
            ToggleSecureTextField(t.translate("loginForm.password_placeholder", "Password hint"), text: $password)
                .padding([.vertical])
                .focused($passwordHasFocus)
                .disabled(disabled)
                .onChange(of: viewModel.passwordHasFocus) { passwordHasFocus = $0 }
                .onSubmit { authenticate() }

            if viewModel.isDebuggable {
                Button("Login Debug") {
                    emailAddress = viewModel.appSettings.debugEmailAddress
                    password = viewModel.appSettings.debugAccountPassword
                    authenticate()
                }
                .buttonStyle(buttonStyle)
                .padding([.vertical])
                .disabled(disabled)
            }

            Button {
                authenticate()
            } label: {
                BusyButtonContent(
                    isBusy: viewModel.isAuthenticating,
                    text: t.translate("actions.login", "Login action")
                )
            }
            .buttonStyle(buttonStyle)
            .padding([.vertical])
            .disabled(disabled)

            if viewModel.viewData.hasAccessToken {
                Button {
                    dismissScreen()
                } label:  {
                    BusyButtonContent(
                        isBusy: viewModel.isAuthenticating,
                        text: t.translate("actions.cancel", "Cancel action")
                    )
                }
                .buttonStyle(buttonStyle)
                .padding([.vertical])
                .disabled(disabled)
            }
        }
        .padding()
    }
}

struct LogoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @ObservedObject var viewModel: AuthenticateViewModel
    var logout: () -> ()
    var dismissScreen: () -> ()

    var body: some View {
        let disabled = viewModel.isAuthenticating
        let buttonStyle = PrimaryButtonStyle(disabled)

        VStack {
            let errorMessage = $viewModel.errorMessage.wrappedValue
            if !errorMessage.isBlank {
                Text(errorMessage)
                    .padding([.vertical])
            }

            Button {
                logout()
            } label: {
                BusyButtonContent(
                    isBusy: viewModel.isAuthenticating,
                    text: t.translate("actions.logout", "Logout action")
                )
            }
            .buttonStyle(buttonStyle)
            .padding([.vertical])
            .disabled(disabled)

            if viewModel.viewData.hasAccessToken {
                Button {
                    dismissScreen()
                } label:  {
                    BusyButtonContent(
                        isBusy: viewModel.isAuthenticating,
                        text: t.translate("actions.cancel", "Cancel action")
                    )
                }
                .buttonStyle(buttonStyle)
                .padding([.vertical])
                .disabled(disabled)
            }
        }
        .padding()
    }
}
