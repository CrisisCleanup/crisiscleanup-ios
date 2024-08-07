import SwiftUI

struct LoginWithPhoneView: View {
    @ObservedObject var viewModel: LoginWithPhoneViewModel

    var body: some View {
        ZStack {
            if viewModel.viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else {
                LoginView(
                    viewModel: viewModel
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

    @ObservedObject var viewModel: LoginWithPhoneViewModel
    @ObservedObject var focusableViewState = TextInputFocusableView()

    @State var phoneNumber = ""

    @FocusState private var focusState: TextInputFocused?

    func requestPhoneCode() {
        viewModel.requestPhoneCode(phoneNumber)
    }

    var body: some View {
        let disabled = viewModel.isRequestingCode

        VStack {
            ScrollCenterContent {
                CrisisCleanupLogoView()

                VStack {
                    Text(t.translate("actions.login", "Login action"))
                        .fontHeader1()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                        .accessibilityIdentifier("phoneLoginHeaderText")

                    let errorMessage = viewModel.errorMessage
                    if !errorMessage.isBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.vertical])
                            .accessibilityIdentifier("phoneLoginError")
                    }

                    TextField(t.t("loginWithPhone.enter_cell"), text: $phoneNumber)
                        .textFieldBorder()
                        .keyboardType(.phonePad)
                        .padding(.top, appTheme.listItemVerticalPadding)
                        .focused($focusState, equals: TextInputFocused.authPhone)
                        .disabled(disabled)
                        .onSubmit {
                            if !phoneNumber.isBlank {
                                requestPhoneCode()
                            }
                        }
                        .onAppear {
                            if phoneNumber.isBlank {
                                focusState = .authPhone
                            }
                        }
                        .onChange(of: focusState) { focusableViewState.focusState = $0 }
                        .accessibilityIdentifier("phoneLoginTextField")

                    Button {
                        requestPhoneCode()
                    } label: {
                        BusyButtonContent(
                            isBusy: viewModel.isRequestingCode,
                            text: t.t("loginForm.login_with_cell")
                        )
                    }
                    .stylePrimary()
                    .padding(.vertical, appTheme.listItemVerticalPadding)
                    .disabled(disabled)
                    .onChange(of: viewModel.openPhoneCodeLogin) { newValue in
                        if (newValue) {
                            router.openPhoneLoginCode(phoneNumber)
                            viewModel.openPhoneCodeLogin = false
                        }
                    }
                    .accessibilityIdentifier("phoneLoginAction")
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
        .environmentObject(focusableViewState)
    }
}
