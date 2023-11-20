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

private struct LoginView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithPhoneViewModel
    @ObservedObject var focusableViewState = TextInputFocusableView()

    let dismissScreen: () -> Void

    @State var phoneCode: String = ""

    @FocusState private var focusState: TextInputFocused?

    func authenticate(_ code: String) {
        viewModel.authenticate(code)
    }

    var body: some View {
        let disabled = viewModel.isAuthenticating

        VStack {
            ScrollView {
                VStack {
                    let errorMessage = viewModel.errorMessage
                    if !errorMessage.isBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.vertical])
                    }

                    // TODO: Code input and action
                    //       t.t("~~Enter the 5 digit code we sent to")
                    //       Partially obfuscated phone number
                    //       Single digit code inputs
                    //       Resend code link

                    // TODO: Show account dropdown if there are multiple accounts linked to this number
                    //.onChange(of: focusState) { focusableViewState.focusState = $0 }

                    Button {
                        authenticate(phoneCode)
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
