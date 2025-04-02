import SwiftUI

struct LoginWithEmailView: View {
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithEmailViewModel

    var body: some View {
        ZStack {
            let viewData = viewModel.viewData
            if viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else {
                LoginView(
                    viewModel: viewModel,
                    emailAddress: viewData.accountData.emailAddress
                )
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct LoginView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithEmailViewModel
    @ObservedObject var focusableViewState = TextInputFocusableView()

    @State var emailAddress: String = ""
    @State var password: String = ""

    @FocusState private var focusState: TextInputFocused?

    func authenticate() {
        viewModel.authenticate(emailAddress, password)
    }

    var body: some View {
        let disabled = viewModel.isAuthenticating

        VStack {
            ScrollCenterContent {
                CrisisCleanupLogoView()

                VStack {
                    Text(t.translate("actions.login", "Login action"))
                        .fontHeader1()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                        .accessibilityIdentifier("loginEmailHeaderText")

                    let errorMessage = viewModel.errorMessage
                    if !errorMessage.isBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.vertical])
                            .accessibilityIdentifier("emailLoginError")
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
                            .onSubmit {
                                if password.isBlank {
                                    focusState = .authPassword
                                } else {
                                    authenticate()
                                }
                            }
                            .onAppear {
                                if emailAddress.isBlank {
                                    focusState = .authEmailAddress
                                }
                            }
                            .accessibilityIdentifier("loginEmailTextField")
                        ToggleSecureTextField(
                            t.translate("loginForm.password_placeholder", "Password hint"),
                            text: $password,
                            focusState: $focusState,
                            focusedKey: .authPassword
                        )
                        .padding([.vertical])
                        .disabled(disabled)
                        .onSubmit {
                            if emailAddress.isBlank {
                                focusState = .authEmailAddress
                            } else {
                                authenticate()
                            }
                        }
                        .accessibilityIdentifier("loginPasswordTextField")
                    }
                    .onChange(of: focusState) { focusableViewState.focusState = $0 }

                    Button(t.t("actions.request_magic_link")) {
                        router.openEmailMagicLink()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom)
                    .disabled(disabled)
                    .accessibilityIdentifier("loginRequestMagicLinkAction")

                    Button(t.t("loginForm.login_with_cell")) {
                        router.openPhoneLogin(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom)
                    .disabled(disabled)
                    .accessibilityIdentifier("loginWithPhoneAction")

                    Button(t.t("invitationSignup.forgot_password")) {
                        router.openForgotPassword()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom)
                    .disabled(disabled)
                    .accessibilityIdentifier("loginForgotPasswordAction")

                    if viewModel.isDebuggable {
                        Button("Login Debug") {
                            emailAddress = viewModel.appSettings.debugEmailAddress
                            password = viewModel.appSettings.debugAccountPassword
                            authenticate()
                        }
                        .stylePrimary()
                        .padding(.vertical, appTheme.listItemVerticalPadding)
                        .disabled(disabled)
                        .accessibilityIdentifier("emailLoginDebugLoginAction")
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
                    .accessibilityIdentifier("emailLoginLoginAction")
                }
                .onChange(of: viewModel.focusState) { focusState = $0 }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)

            if focusableViewState.isFocused {
                OpenKeyboardActionsView()
            }
        }
        .environmentObject(focusableViewState)
    }
}
