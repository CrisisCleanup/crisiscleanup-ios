import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ResetPasswordViewModel

    // TODO: Incorporate or remove
    let close: () -> Void

    @ObservedObject var focusableViewState = TextInputFocusableView()

    @FocusState private var focusState: TextInputFocused?

    private func updateFocus(_ focus: TextInputFocused) {
        focusState = focus
    }

    var body: some View {
        let disabled = viewModel.editableViewState.disabled

        ScrollView {
            VStack(alignment: .leading, spacing: appTheme.gridActionSpacing) {
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
            }
            .padding([.horizontal, .top])
            .onChange(of: viewModel.resetPasswordErrorMessage) { newValue in
                if newValue.isNotBlank {
                    updateFocus(.authPassword)
                }
            }
            .onChange(of: viewModel.resetPasswordConfirmErrorMessage) { newValue in
                if newValue.isNotBlank {
                    updateFocus(.authConfirmPassword)
                }
            }
            .onChange(of: focusState) { focusableViewState.focusState = $0 }
        }
        .scrollDismissesKeyboard(.immediately)
        .screenTitle(t.t("actions.reset_password"))
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(focusableViewState)
    }
}
