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
                    .padding()

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

        ScrollView {
            VStack(alignment: .leading) {
                if showEmailInput {
                    Group {
                        let requestInstructions = t.t("requestAccess.request_access_enter_email")
                        Text(requestInstructions)
                            .padding(.bottom, appTheme.listItemVerticalPadding)

                        if viewModel.emailAddressError.isNotBlank {
                            Text(viewModel.emailAddressError)
                                .foregroundColor(appTheme.colors.primaryRedColor)
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
                    }
                    .padding(.horizontal)
                } else {
                    if let displayInfo = inviteDisplay {
                        if let avatarUrl = displayInfo.avatarUrl,
                           displayInfo.displayName.isNotBlank,
                           displayInfo.inviteMessage.isNotBlank {
                            HStack(spacing: appTheme.gridItemSpacing) {
                                AvatarView(
                                    url: avatarUrl,
                                    isSvg: displayInfo.isSvgAvatar
                                )

                                VStack(alignment: .leading) {
                                    Text(displayInfo.displayName)
                                        .fontHeader4()
                                    Text(displayInfo.inviteMessage)
                                        .fontBodySmall()
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // TODO: Show loading
                    }
                }

                Text(t.t("requestAccess.complete_form_request_access"))
                    .fontHeader3()
                    .padding()

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
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// TODO: Move (and preview) into DesignSystem or UI module
internal struct RegisterSuccessView: View {
    let title: String
    let message: String

    var body: some View {
        Spacer()

        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .frame(width: 64, height: 64)
            .foregroundColor(statusClosedColor)

        Text(title)
            .fontHeader1()
            .padding()

        Text(message)
            .padding(.horizontal)

        Spacer()

        Image("worker_wheelbarrow_world_background", bundle: .module)
            .offset(CGSize(width: 90.0, height: 0.0))

        Spacer()
    }
}

struct RegisterSuccessView_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            RegisterSuccessView(
                title: "A long wrapping title stretching beyond the thin screen",
                message: "An even longer message unfit for single line display so must spill onto the untouched space below."
            )
        }
    }
    static var previews: some View {
        Preview()
    }
}
