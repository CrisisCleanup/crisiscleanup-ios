import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ResetPasswordViewModel

    let close: () -> Void

    private let focusableViewState = TextInputFocusableView()

    @FocusState private var focusState: TextInputFocused?

    private func updateFocus(_ focus: TextInputFocused) {
        focusState = focus
    }

    var body: some View {
        let disabled = viewModel.editableViewState.disabled

        ZStack {
            ScrollView {
                // TODO: Common dimensions
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isPasswordReset {
                        Text(t.t("resetPassword.password_reset"))
                            .fontHeader3()
                            .padding(.vertical, appTheme.listItemVerticalPadding)
                    } else {
                        Text(t.t("resetPassword.forgot_your_password_or_reset"))
                            .fontHeader3()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(t.t("resetPassword.enter_email_for_reset_instructions"))

                        let passwordErrorMessage = viewModel.resetPasswordErrorMessage.ifBlank {
                            viewModel.resetPasswordConfirmErrorMessage
                        }
                        let hasError = passwordErrorMessage.isNotBlank
                        if hasError {
                            Text(passwordErrorMessage)
                                .foregroundColor(appTheme.colors.primaryRedColor)
                        }

                        ToggleSecureTextField(
                            t.t("resetPassword.password"),
                            text: $viewModel.password,
                            focusState: $focusState,
                            focusedKey: .authPassword
                        )
                        .disabled(disabled)
                        .onSubmit { focusState = .authConfirmPassword }
                        .onAppear {
                            focusState = .authPassword
                        }

                        ToggleSecureTextField(
                            t.t("resetPassword.confirm_password"),
                            text: $viewModel.confirmPassword,
                            focusState: $focusState,
                            focusedKey: .authConfirmPassword
                        )
                        .disabled(disabled)
                        .onSubmit { viewModel.onResetPassword() }
                    }

                    Button {
                        viewModel.onResetPassword()
                    } label: {
                        BusyButtonContent(
                            isBusy: viewModel.isResettingPassword,
                            text: t.t("actions.reset_password")
                        )
                    }
                    .stylePrimary()
                    .disabled(disabled)
                }
                .padding([.horizontal, .top])
                .onChange(of: viewModel.resetPasswordErrorMessage) { newValue in
                    if newValue.isNotBlank {
                        updateFocus(.authPassword)
                    }
                }
                .onReceive(viewModel.$resetPasswordConfirmErrorMessage) { newValue in
                    print("Confirm error \(newValue)")
                    if newValue.isNotBlank {
                        updateFocus(.authConfirmPassword)
                    }
                }
                .onChange(of: focusState) { focusableViewState.focusState = $0 }
            }
        }
        .screenTitle(t.t("actions.reset_password"))
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(focusableViewState)
    }
}
