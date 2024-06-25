import SwiftUI

struct RequestOrgAccessView: View {
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
                RegisterSuccessView(
                    title: viewModel.requestSentTitle,
                    message: viewModel.requestSentText
                )
            } else {
                RequestOrgUserInfoInputView(
                    showEmailInput: viewModel.showEmailInput,
                    inviteDisplay: $viewModel.inviteDisplay,
                    focusState: $focusState
                )

                Spacer()

                if focusableViewState.isFocused {
                    OpenKeyboardActionsView()
                }
            }
        }
        .navigationTitle(viewModel.screenTitle)
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

    var showEmailInput = false
    @Binding var inviteDisplay: InviteDisplayInfo?

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        let disabled = editableView.disabled
        let isLoading = viewModel.isLoading

        ScrollCenterContent(contentPadding: .top) {
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
                        .disabled(disabled)
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
            .disabled(disabled)
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
                .disabled(disabled)
                .accessibilityIdentifier("requestAccessSubmitAction")
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
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
