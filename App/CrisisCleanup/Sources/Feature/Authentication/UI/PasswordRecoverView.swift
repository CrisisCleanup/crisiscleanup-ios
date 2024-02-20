import SwiftUI

struct PasswordRecoverView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: PasswordRecoverViewModel

    @State private var animateIsBusy = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if viewModel.isPasswordResetInitiated {
                        Text(t.t("resetPassword.email_arrive_soon_check_junk"))
                            .fontHeader3()
                            .listItemModifier()

                    } else if viewModel.isMagicLinkInitiated {
                        Text(t.t("magicLink.magic_link_sent"))
                            .fontHeader3()
                            .listItemModifier()

                    } else {
                        if viewModel.showForgotPassword {
                            ForgotPasswordView()
                                .padding(.bottom)
                        }

                        if viewModel.showMagicLink {
                            MagicLinkView()
                                .padding(.bottom)
                        }
                    }
                }
            }

            if animateIsBusy {
                ProgressView()
            }
        }
        .screenTitle(t.t(viewModel.screenTitleKey))
        .onChange(of: viewModel.isBusy, perform: { isBusy in
            animateIsBusy = isBusy
        })
        .onChange(of: viewModel.isPasswordChangedRecently, perform: { newValue in
            if newValue {
                dismiss()
            }
        })
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(viewModel.editableViewState)
    }
}

private struct ForgotPasswordView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: PasswordRecoverViewModel
    @EnvironmentObject var editableView: EditableView

    var body: some View {
        let disabled = editableView.disabled

        Text(t.t("resetPassword.forgot_your_password_or_reset"))
            .fontHeader3()
            .padding(.horizontal)
            .padding(.top, appTheme.listItemVerticalPadding)

        Text(t.t("resetPassword.enter_email_for_reset_instructions"))
            .padding(.horizontal)

        let emailErrorMessage = viewModel.forgotPasswordErrorMessage
        let hasError = emailErrorMessage.isNotBlank
        if hasError {
            Text(emailErrorMessage)
                .foregroundColor(appTheme.colors.primaryRedColor)
                .padding(.horizontal)
        }

        TextField(t.translate("loginForm.email_placeholder", "Email hint"), text: $viewModel.emailAddress)
            .textFieldBorder()
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding(.horizontal)
            .disableAutocorrection(true)
            .disabled(disabled)
            .onSubmit { viewModel.onInitiatePasswordReset() }

        Button {
            viewModel.onInitiatePasswordReset()
        } label: {
            BusyButtonContent(
                isBusy: viewModel.isBusy,
                text: t.t("actions.reset_password")
            )
        }
        .stylePrimary()
        .padding(.horizontal)
        .disabled(disabled)
        .accessibilityIdentifier("forgotPasswordAction")
    }
}

private struct MagicLinkView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: PasswordRecoverViewModel
    @EnvironmentObject var editableView: EditableView

    var body: some View {
        let disabled = editableView.disabled

        Text(t.t("actions.request_magic_link"))
            .fontHeader3()
            .padding(.horizontal)
            .padding(.top, appTheme.listItemVerticalPadding)

        Text(t.t("magicLink.magic_link_description"))
            .padding(.horizontal)

        let emailErrorMessage = viewModel.magicLinkErrorMessage
        let hasError = emailErrorMessage.isNotBlank
        if hasError {
            Text(emailErrorMessage)
                .foregroundColor(appTheme.colors.primaryRedColor)
                .padding(.horizontal)
        }

        TextField(t.translate("loginForm.email_placeholder", "Email hint"), text: $viewModel.emailAddress)
            .textFieldBorder()
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding(.horizontal)
            .disableAutocorrection(true)
            .disabled(disabled)
            .onSubmit { viewModel.onInitiateMagicLink() }

        Button {
            viewModel.onInitiateMagicLink()
        } label: {
            BusyButtonContent(
                isBusy: viewModel.isBusy,
                text: t.t("actions.submit")
            )
        }
        .stylePrimary()
        .padding(.horizontal)
        .disabled(disabled)
        .accessibilityIdentifier("emailMagicLinkAction")
    }
}
