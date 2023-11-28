import SwiftUI

struct LoginPhoneCodeView: View {
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithPhoneViewModel

    let dismiss: () -> Void

    var body: some View {
        ZStack {
            if viewModel.viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else {
                LoginView(
                    viewModel: viewModel,
                    dismissScreen: dismiss
                )
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
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

    @ObservedObject var viewModel: LoginWithPhoneViewModel
    @ObservedObject var focusableViewState = TextInputFocusableView()

    let dismissScreen: () -> Void

    @State var singleCodes: [String] = ["", "", "", "", "", ""]

    @FocusState private var focusState: SingleCodeFocused?

    func authenticate(_ code: String) {
        viewModel.authenticate(code)
    }

    var body: some View {
        let disabled = viewModel.isAuthenticating

        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    let errorMessage = viewModel.errorMessage
                    if !errorMessage.isBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.vertical])
                    }

                    // TODO: Code input and action
                    Text(t.t("~~Enter the 5 digit code we sent to"))
                    Text(viewModel.obfuscatedPhoneNumber)

                    // TODO: Autofill from text messages
                    HStack {
                        ForEach(0..<singleCodes.count, id: \.self) { i in
                            TextField("", text: $singleCodes[i])
                                .textFieldBorder()
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .focused($focusState, equals: .code(index: i))
                                .disabled(disabled)
                                .onChange(of: singleCodes[i], perform: { newValue in
                                    if newValue.count > 1 {
                                        singleCodes[i] = String(newValue[newValue.index(newValue.endIndex, offsetBy: -1)])
                                    }
                                    if i >= singleCodes.count - 1 {
                                        // TODO: Submit
                                    } else {
                                        focusState = .code(index: i+1)
                                    }
                                })
                                .onSubmit {
                                    // TODO: Submit or error
                                }
                                .onAppear {
                                    focusState = .code(index: 0)
                                }
                        }
                    }

                    // TODO: Resend code link

                    // TODO: Show account dropdown if there are multiple accounts linked to this number
                    //.onChange(of: focusState) { focusableViewState.focusState = $0 }

                    Button {
                        authenticate(singleCodes.joined(separator: ""))
                    } label: {
                        BusyButtonContent(
                            isBusy: viewModel.isAuthenticating,
                            text: t.t("actions.submit")
                        )
                    }
                    .stylePrimary()
                    .padding(.vertical, appTheme.listItemVerticalPadding)
                    .disabled(disabled)
                }
                .onChange(of: viewModel.codeFocusState) { focusState = $0 }
                .frame(maxWidth: .infinity, alignment: .leading)
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
