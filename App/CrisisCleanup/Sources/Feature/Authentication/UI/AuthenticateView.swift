import SwiftUI

struct AuthenticateView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

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
    @ObservedObject var focusableViewState = TextInputFocusableView()

    let dismissScreen: () -> Void

    @State var emailAddress: String = ""
    @State var password: String = ""

    @FocusState private var focusState: TextInputFocused?

    func authenticate() {
        viewModel.authenticate(emailAddress, password)
    }

    var body: some View {
        let disabled = viewModel.isAuthenticating

        VStack {
            ScrollView {
                CrisisCleanupLogoView()

                VStack {
                    Text(t.translate("actions.login", "Login action"))
                        .fontHeader2()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)

                    let errorMessage = viewModel.errorMessage
                    if !errorMessage.isBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.vertical])
                    }

                    Group {
                        TextField(t.translate("loginForm.email_placeholder", "Email hint"), text: $emailAddress)
                            .textFieldBorder()
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.top, appTheme.listItemVerticalPadding)
                            .disableAutocorrection(true)
                            .focused($focusState, equals: TextInputFocused.authEmailAddress)
                            .disabled(disabled)
                            .onSubmit { authenticate() }
                            .onAppear { focusState = TextInputFocused.authEmailAddress }
                        ToggleSecureTextField(t.translate("loginForm.password_placeholder", "Password hint"), text: $password)
                            .padding([.vertical])
                            .focused($focusState, equals: TextInputFocused.authPassword)
                            .disabled(disabled)
                            .onSubmit { authenticate() }
                    }
                    .onChange(of: focusState) { focusableViewState.focusState = $0 }

                    HStack {
                        // TODO: Email link when Universal links are ready

                        // TODO: Forgot password action
                    }

                    if viewModel.isDebuggable {
                        Button("Login Debug") {
                            emailAddress = viewModel.appSettings.debugEmailAddress
                            password = viewModel.appSettings.debugAccountPassword
                            authenticate()
                        }
                        .stylePrimary()
                        .padding(.vertical, appTheme.listItemVerticalPadding)
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
                    .padding(.vertical, appTheme.listItemVerticalPadding)
                    .disabled(disabled)

                    if viewModel.viewData.hasAuthenticated {
                        Button {
                            dismissScreen()
                        } label:  {
                            Text(t.t("actions.back"))
                        }
                        .padding(.vertical, appTheme.listItemVerticalPadding)
                        .disabled(disabled)
                    }
                }
                .onChange(of: viewModel.focusState) { focusState = $0 }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)

            Spacer()

            if focusableViewState.isFocused {
                OpenKeyboardActionsView()
            }
        }
    }
}

private struct CrisisCleanupLogoView: View {
    var body: some View {
        HStack {
            Image("crisis_cleanup_logo", bundle: .module)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180)
                .overlay {
                    Image("worker_wheelbarrow_world_background", bundle: .module)
                        .padding(.leading, 360)
                        .padding(.top, 176)
                }
                .padding(.top, 32)
                .padding(.bottom, 128)
                .padding(.leading, 24)
            Spacer()
        }
    }
}

struct LogoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @ObservedObject var viewModel: AuthenticateViewModel
    var logout: () -> ()
    var dismissScreen: () -> ()

    var body: some View {
        let disabled = viewModel.isAuthenticating

        ScrollView {
            CrisisCleanupLogoView()
                .padding(.bottom)

            VStack{
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
                        text: t.t("actions.logout")
                    )
                }
                .stylePrimary()
                .padding([.vertical])
                .disabled(disabled)

                Button {
                    dismissScreen()
                } label:  {
                    Text(t.t("actions.back"))
                }
                .padding(.vertical, appTheme.listItemVerticalPadding)
                .disabled(disabled)
            }
            .padding()
        }
    }
}
