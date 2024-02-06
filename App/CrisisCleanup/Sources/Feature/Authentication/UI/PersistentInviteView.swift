import SwiftUI

struct PersistentInviteView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: PersistentInviteViewModel

    @ObservedObject var focusableViewState = TextInputFocusableView()
    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        ZStack {
            VStack {
                if viewModel.inviteFailMessage.isNotBlank {
                    Text(viewModel.inviteFailMessage)
                        .fontHeader3()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                    Spacer()

                } else if viewModel.isInviteAccepted {
                    RegisterSuccessView(
                        title: viewModel.acceptedTitle,
                        message: ""
                    )
                } else if let inviteDisplay = viewModel.inviteDisplay {
                    let inviteInfo = inviteDisplay.inviteInfo
                    if inviteInfo.isExpiredInvite {
                        Text(t.t("persistentInvitations.expired_or_invalid"))
                            .fontHeader3()
                            .listItemModifier()

                        Spacer()
                    } else {
                        PersistentInviteInfoInputView(
                            inviteDisplay: inviteDisplay,
                            focusState: $focusState
                        )

                        Spacer()

                        if focusableViewState.isFocused {
                            OpenKeyboardActionsView()
                        }
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle(t.t("actions.sign_up"))
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

private struct PersistentInviteInfoInputView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: PersistentInviteViewModel
    @EnvironmentObject var editableView: EditableView

    var inviteDisplay: InviteDisplayInfo

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        let disabled = editableView.disabled
        let isJoiningOrg = viewModel.isJoiningOrg

        ScrollView {
            VStack(alignment: .leading) {
                if Date.now.distance(to: inviteDisplay.inviteInfo.expiration) < 1.days {
                    let expirationText = t.t("persistentInvitations.invite_expires_in_x_days")
                        .replacingOccurrences(of: "{relative_time}", with: inviteDisplay.inviteInfo.expiration.relativeTime)
                    Text(expirationText)
                        .listItemModifier()
                }

                if let avatarUrl = inviteDisplay.avatarUrl,
                   inviteDisplay.displayName.isNotBlank,
                   inviteDisplay.inviteMessage.isNotBlank {
                    HStack(spacing: appTheme.gridItemSpacing) {
                        AvatarView(
                            url: avatarUrl,
                            isSvg: inviteDisplay.isSvgAvatar
                        )

                        VStack(alignment: .leading) {
                            Text(inviteDisplay.displayName)
                                .fontHeader4()
                            Text(inviteDisplay.inviteMessage)
                                .fontBodySmall()
                        }
                    }
                    .padding([.horizontal, .bottom])
                }

                Text(t.t("persistentInvitations.enter_user_info"))
                    .fontHeader3()
                    .padding([.horizontal, .bottom])

                UserInfoInputView(
                    languageOptions: $viewModel.languageOptions,
                    info: $viewModel.userInfo,
                    focusState: focusState
                )
                .padding(.horizontal)
                .disabled(disabled)

                Button {
                    viewModel.onVolunteerWithOrg()
                } label: {
                    BusyButtonContent(
                        isBusy: isJoiningOrg,
                        text: t.t("actions.request_access")
                    )
                }
                .stylePrimary()
                .padding([.horizontal, .bottom])
                .disabled(disabled)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}
