import SwiftUI

struct LoginPhoneCodeView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithPhoneViewModel

    var body: some View {
        ZStack {
            if viewModel.viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else if viewModel.phoneNumber.isBlank {
                VStack(alignment: .leading) {
                    Text(t.t("loginWithPhone.invalid_phone_try_again"))

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            } else {
                LoginView()
            }
        }
        .navigationTitle(t.t("actions.login"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct LoginView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: LoginWithPhoneViewModel

    @State var phoneCode = ""
    private let codeLength = 6

    func authenticate(_ code: String) {
        let code = code.trim()
        if code.count >= codeLength - 1 {
            viewModel.authenticate(code)
            UIApplication.shared.closeKeyboard()
        } else {
            viewModel.onIncompleteCode()
            // TODO: Focus on input
        }
    }

    var body: some View {
        let disabled = viewModel.isExchangingCode

        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    let errorMessage = viewModel.errorMessage
                    if errorMessage.isNotBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .padding([.vertical])
                            .accessibilityIdentifier("verifyPhoneCodeError")
                    }

                    Text(t.t("loginWithPhone.enter_x_digit_code")
                         // TODO: Use configurable value
                        .replacingOccurrences(of: "{codeCount}", with: "\(codeLength)"))
                    Text(viewModel.obfuscatedPhoneNumber)

                    // TODO: Autofill from text messages
                    TextField("", text: $phoneCode)
                        .textFieldBorder()
                        .keyboardType(.numberPad)
                        .disabled(disabled || viewModel.isSelectAccount)
                        .onSubmit {
                            authenticate(phoneCode)
                        }
                        .onAppear {
                            // TODO: Focus on input
                        }

                    Group {
                        Button(t.t("actions.resend_code")) {
                            viewModel.requestPhoneCode(viewModel.phoneNumber)
                            phoneCode = ""
                        }
                        .disabled(disabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    if viewModel.accountOptions.count > 1 {
                        Text(t.t("loginWithPhone.phone_associated_multiple_users"))
                            .padding(.top)

                        Text(t.t("actions.select_account"))
                            .fontHeader4()

                        Menu {
                            ForEach(viewModel.accountOptions, id: \.userId) { accountInfo in
                                Button(accountInfo.accountDisplay) {
                                    viewModel.onAccountSelected(accountInfo)
                                }
                            }
                        } label: {
                            Group {
                                let accountDisplay = viewModel.selectedAccount.accountDisplay
                                if accountDisplay.isBlank {
                                    Text(t.t("actions.select_account"))
                                        .foregroundColor(appTheme.colors.primaryRedColor)
                                } else {
                                    Text(accountDisplay)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .foregroundColor(.black)
                        }
                        .textFieldBorder()
                        .disabled(disabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)

            Spacer()

            Button {
                authenticate(phoneCode)
            } label: {
                BusyButtonContent(
                    isBusy: viewModel.isExchangingCode,
                    text: t.t("actions.submit")
                )
            }
            .stylePrimary()
            .padding()
            .disabled(disabled)
        }
    }
}
