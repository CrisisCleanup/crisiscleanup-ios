import SwiftUI

struct LoginPhoneCodeView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithPhoneViewModel

    let dismiss: () -> Void

    var body: some View {
        ZStack {
            if viewModel.viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else if viewModel.phoneNumber.isBlank {
                VStack(alignment: .leading) {
                    Text(t.t("~~Invalid phone number. Go back and retry phone login."))

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            } else {
                LoginView(
                    dismissScreen: dismiss
                )
            }
        }
        .navigationTitle(t.t("actions.login"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .onReceive(viewModel.$isAuthenticateSuccessful) { b in
            if b {
                router.returnToAuth()
                dismiss()
            }
        }
    }
}

enum SingleCodeFocused: Hashable {
  case none
  case code(index: Int)
}

private struct LoginView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: LoginWithPhoneViewModel

    let dismissScreen: () -> Void

    @State var singleCodes: [String] = ["", "", "", "", "", ""]

    @FocusState private var focusState: SingleCodeFocused?

    func authenticate(_ singleCodes: [String]) {
        let fullCode = singleCodes
            .map { $0.trim() }
            .filter { $0.isNotBlank }
            .map { $0.substring($0.count-1, $0.count) }
            .joined(separator: "")

        if fullCode.count < singleCodes.count {
            singleCodes.enumerated().forEach { (i, s) in
                if s.isBlank {
                    focusState = .code(index: i)
                    return
                }
            }
        } else {
            viewModel.authenticate(singleCodes.joined(separator: ""))
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
                    }

                    Text(t.t("~~Enter the \(singleCodes.count) digit code we sent to"))
                    Text(viewModel.obfuscatedPhoneNumber)

                    // TODO: Autofill from text messages
                    HStack {
                        ForEach(0..<singleCodes.count, id: \.self) { i in
                            TextField("", text: $singleCodes[i])
                                .textFieldBorder()
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .focused($focusState, equals: .code(index: i))
                                .disabled(disabled || viewModel.isSelectAccount)
                                .onChange(of: singleCodes[i], perform: { newValue in
                                    // TODO: Set entire code if length matches and code is blank

                                    if newValue.count > 1 {
                                        singleCodes[i] = String(newValue[newValue.index(newValue.endIndex, offsetBy: -1)])
                                    }
                                    if newValue.isNotBlank {
                                        focusState = i >= singleCodes.count - 1 ? nil : .code(index: i+1)
                                    }
                                })
                                .onSubmit {
                                    authenticate(singleCodes)
                                }
                                .onAppear {
                                    focusState = .code(index: 0)
                                }
                        }
                    }

                    Group {
                        Button(t.t("~~Resend Code")) {
                            viewModel.requestPhoneCode(viewModel.phoneNumber)
                        }
                        .disabled(disabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    if viewModel.accountOptions.count > 1 {
                        Text(t.t("~~This phone number is associated with multiple accounts."))
                            .padding(.top)

                        Text(t.t("~~Select Account"))
                            .fontHeader4()

                        Menu {
                            ForEach(viewModel.accountOptions, id: \.userId) { accountInfo in
                                Button(accountInfo.accountDisplay) {
                                    viewModel.selectedAccount = accountInfo
                                }
                            }
                        } label: {
                            Group {
                                Text(viewModel.selectedAccount.accountDisplay)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .foregroundColor(.black)
                        }
                        .textFieldBorder()
                        .disabled(disabled)
                    }
                }
                .onChange(of: viewModel.codeFocusState) { focusState = $0 }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)

            Spacer()

            Button {
                authenticate(singleCodes)
            } label: {
                BusyButtonContent(
                    isBusy: viewModel.isExchangingCode,
                    text: t.t("actions.submit")
                )
            }
            .stylePrimary()
            .padding()
            .disabled(disabled)

            if focusState != nil {
                OpenKeyboardActionsView()
            }
        }
    }
}
