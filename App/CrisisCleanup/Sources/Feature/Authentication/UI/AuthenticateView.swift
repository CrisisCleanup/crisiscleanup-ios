import SwiftUI

struct AuthenticateView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: AuthenticateViewModel
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            let viewData = viewModel.viewData
            if viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else {
                if viewData.isAccountValid {
                    let logout = { viewModel.logout() }
                    LogoutView(
                        viewModel: viewModel,
                        logout: logout,
                        dismissScreen: dismiss
                    )
                } else {
                    LoginView(
                        viewModel: viewModel,
                        dismissScreen: dismiss,
                        emailAddress: viewData.accountData.emailAddress
                    )
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onReceive(viewModel.$isAuthenticateSuccessful) { b in
            if b {
                dismiss()
            }
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
                .stylePrimary()
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
            .stylePrimary()
            .padding([.vertical])
            .disabled(disabled)

            if viewModel.viewData.hasAuthenticated {
                Button {
                    dismissScreen()
                } label:  {
                    BusyButtonContent(
                        isBusy: viewModel.isAuthenticating,
                        text: t.translate("actions.cancel", "Cancel action")
                    )
                }
                .stylePrimary()
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
            .stylePrimary()
            .padding([.vertical])
            .disabled(disabled)

            Button {
                dismissScreen()
            } label:  {
                BusyButtonContent(
                    isBusy: viewModel.isAuthenticating,
                    text: t.translate("actions.cancel", "Cancel action")
                )
            }
            .stylePrimary()
            .padding([.vertical])
            .disabled(disabled)
        }
        .padding()
    }
}
