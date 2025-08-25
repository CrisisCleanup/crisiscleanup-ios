import SwiftUI

struct RequestOrgAccessView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: RequestOrgAccessViewModel

    @ObservedObject var focusableViewState = TextInputFocusableView()
    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        VStack {
            if viewModel.inviteInfoErrorMessage.isNotBlank {
                Text(viewModel.inviteInfoErrorMessage)
                    .fontHeader3()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .accessibilityIdentifier("requestAccessInviteInfoError")

                Spacer()

            } else if viewModel.isInviteRequested {
                let actionText = viewModel.showEmailInput ? "" : t.t("actions.login")
                RegisterSuccessView(
                    title: viewModel.requestSentTitle,
                    message: viewModel.requestSentText,
                    actionText: actionText,
                    onAction: { router.openEmailLogin(true) }
                )
            } else if viewModel.isOrgTransferred {
                let orgName = viewModel.inviteDisplay?.inviteInfo.orgName ?? ""
                OrgTransferSuccessView(orgName: orgName)
            } else {
                RequestOrgUserInfoInputView(
                    inviteDisplay: $viewModel.inviteDisplay,
                    focusState: $focusState
                )

                Spacer()

                if focusableViewState.isFocused {
                    OpenKeyboardActionsView()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if viewModel.isOrgTransferred,
                       viewModel.wasAuthenticated {
                        router.clearRoutes()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.screenTitle)
                    .fontHeader3()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(viewModel.editableViewState)
        .environmentObject(focusableViewState)
        .onChange(of: viewModel.errorFocus) { newValue in
            if let errorFocus = newValue {
                focusState = errorFocus
            }
        }
        .onChange(of: focusState) {
            focusableViewState.focusState = $0
            viewModel.errorFocus = nil
        }
    }
}

private struct RequestOrgUserInfoInputView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: RequestOrgAccessViewModel
    @EnvironmentObject var editableView: EditableView

    @Binding var inviteDisplay: InviteDisplayInfo?

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        let disabled = editableView.disabled
        let isLoading = viewModel.isLoading

        if inviteDisplay == nil {
            ProgressView()
                .circularProgress()
                .padding()
        } else {
            let isExistingUser = inviteDisplay?.inviteInfo.isExistingUser == true
            ScrollCenterContent(contentPadding: .top) {
                if isExistingUser {
                    InviteExistingUserView(
                        isLoading: isLoading,
                        inviteDisplay: $inviteDisplay,
                    )
                    .disabled(disabled)
                } else {
                    InviteNewUserView(
                        focusState: focusState,
                        isLoading: isLoading,
                        inviteDisplay: $inviteDisplay,
                    )
                    .disabled(disabled)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

internal struct InviterAvatarView: View {
    var avatarUrl: URL
    var isSvgAvatar: Bool
    var displayName: String
    var inviteMessage: String

    var body: some View {
        HStack(spacing: appTheme.gridItemSpacing) {
            AvatarView(
                url: avatarUrl,
                isSvg: isSvgAvatar
            )

            VStack(alignment: .leading) {
                Text(displayName)
                    .fontHeader4()
                    .accessibilityIdentifier("inviterAvatarDisplayName")
                Text(inviteMessage)
                    .fontBodySmall()
                    .accessibilityIdentifier("inviterAvatarMessage")
            }
        }
    }
}

private struct InviteExistingUserView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: RequestOrgAccessViewModel

    let isLoading: Bool

    @Binding var inviteDisplay: InviteDisplayInfo?

    @State private var selectedOrgTransfer = TransferOrgOption.notSelected

    var body: some View {
        if let inviteInfo = inviteDisplay?.inviteInfo {
            let transferInstructions = t.t("invitationSignup.inviting_to_transfer_confirm")
                .replacingOccurrences(of: "{user}", with: inviteInfo.displayName)
                .replacingOccurrences(of: "{fromOrg}", with: inviteInfo.fromOrgName)
                .replacingOccurrences(of: "{toOrg}", with: inviteInfo.orgName)
            HtmlTextView(htmlContent: transferInstructions)
                .listItemModifier()

            ForEach(viewModel.transferOrgOptions, id: \.self) { option in
                RadioButton(
                    text: t.t(option.translateKey),
                    isSelected: option == selectedOrgTransfer,
                ) {
                    selectedOrgTransfer = option
                    viewModel.onChangeTransferOrgOption()
                }
                .listItemModifier()
            }

            let errorMessage = viewModel.transferOrgErrorMessage
            if errorMessage.isNotBlank {
                Text(errorMessage)
                    .foregroundStyle(appTheme.colors.primaryRedColor)
                    .listItemModifier()
            }

            Button {
                if selectedOrgTransfer == .doNotTransfer {
                    dismiss()
                } else {
                     viewModel.onTransferOrg(selectedOrgTransfer)
                }
            } label: {
                BusyButtonContent(
                    isBusy: isLoading,
                    text: t.t("actions.transfer")
                )
            }
            .stylePrimary()
            .disabled(selectedOrgTransfer == .notSelected)
            .padding()
            .accessibilityIdentifier("transferOrgSubmitAction")
        }
    }
}

private struct InviteNewUserView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: RequestOrgAccessViewModel

    var focusState: FocusState<TextInputFocused?>.Binding

    let isLoading: Bool

    @Binding var inviteDisplay: InviteDisplayInfo?

    var body: some View {
        let showEmailInput = viewModel.showEmailInput
        if showEmailInput {
            Group {
                let requestInstructions = t.t("requestAccess.request_access_enter_email")
                Text(requestInstructions)
                    .padding(.bottom, appTheme.listItemVerticalPadding)
                    .accessibilityIdentifier("requestAccessByEmailInstructions")

                if viewModel.emailAddressError.isNotBlank {
                    Text(viewModel.emailAddressError)
                        .foregroundColor(appTheme.colors.primaryRedColor)
                        .accessibilityIdentifier("requestAccessByEmailError")
                }
                TextField(t.t("requestAccess.existing_member_email"), text: $viewModel.emailAddress)
                    .textFieldBorder()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused(focusState, equals: TextInputFocused.authEmailAddress)
                    .onSubmit { focusState.wrappedValue = .userEmailAddress }
                    .onAppear {
                        if viewModel.emailAddress.isBlank {
                            focusState.wrappedValue = .authEmailAddress
                        }
                    }
                    .accessibilityIdentifier("requestAccessByEmailTextField")
            }
            .padding(.horizontal)
        } else {
            if let displayInfo = inviteDisplay {
                if let avatarUrl = displayInfo.avatarUrl,
                   displayInfo.displayName.isNotBlank,
                   displayInfo.inviteMessage.isNotBlank {
                    InviterAvatarView(
                        avatarUrl: avatarUrl,
                        isSvgAvatar: displayInfo.isSvgAvatar,
                        displayName: displayInfo.displayName,
                        inviteMessage: displayInfo.inviteMessage
                    )
                    .padding(.horizontal)
                }
            } else {
                // TODO: Show loading
            }
        }

        Text(t.t("requestAccess.complete_form_request_access"))
            .fontHeader3()
            .padding()
            .accessibilityIdentifier("requestAccessInputInstruction")

        UserInfoInputView(
            languageOptions: $viewModel.languageOptions,
            info: $viewModel.userInfo,
            focusState: focusState
        )
        .padding(.horizontal)
        .onAppear {
            if !showEmailInput,
               viewModel.userInfo.emailAddress.isBlank {
                focusState.wrappedValue = .userEmailAddress
            }
        }
        .onChange(of: inviteDisplay) { newValue in
            if let invitedEmail = inviteDisplay?.inviteInfo.invitedEmail,
               viewModel.userInfo.emailAddress.isBlank {
                viewModel.userInfo.emailAddress = invitedEmail
            }
        }

        Group {
            Text(t.t("requestAccess.request_will_be_sent"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("requestAccessSubmitExplainer")

            Button {
                viewModel.onVolunteerWithOrg()
            } label: {
                BusyButtonContent(
                    isBusy: isLoading,
                    text: t.t("actions.request_access")
                )
            }
            .stylePrimary()
            .padding(.bottom)
            .accessibilityIdentifier("requestAccessSubmitAction")
        }
        .padding(.horizontal)
    }
}

private struct OrgTransferSuccessView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    let orgName: String

    var body: some View {
        Text(t.t("invitationSignup.move_completed"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .fontHeader3()

        Text(t.t("invitationSignup.congrats_move_complete")
            .replacingOccurrences(of: "{toOrg}", with: orgName)
        )
        .padding([.horizontal, .bottom])

        Spacer()

        Button(t.t("invitationSignup.forgot_password")) {
            router.openForgotPassword(true)
        }
        .styleOutline()
        .padding([.horizontal, .bottom])

        Button(t.t("actions.login")) {
            router.clearAuthRoutes()
        }
        .stylePrimary()
        .padding([.horizontal, .bottom])
    }
}
