import SwiftUI

struct InviteTeammateView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: InviteTeammateViewModel

    private let focusableViewState = TextInputFocusableView()

    @State private var animateLoading = false

    var body: some View {
        ZStack {
            if animateLoading {
                ProgressView()
            } else if viewModel.isInviteSent {
                // TODO: Show correct invite sent visual
                Text(t.t("Invite was sent"))
            } else if viewModel.hasValidTokens {
                InviteTeammateContentView()
            } else {
                // TODO: Style accordingly
                Text(t.t("Sign in to invite others"))
                    .fontHeader2()
            }
        }
        .hideNavBarUnderSpace()
        .screenTitle(t.t("~~Invite others"))
        .onChange(of: viewModel.isLoading) { newValue in
            animateLoading = newValue
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(focusableViewState)
    }
}

private let searchOrgLeadSpace = 24.0
private struct InviteTeammateContentView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: InviteTeammateViewModel
    @EnvironmentObject var focusableViewState: TextInputFocusableView

    @FocusState private var focusState: TextInputFocused?
    @State private var animateTopSearchBar = false
    @State private var animateSearchOrgLeadSpace = searchOrgLeadSpace

    @State private var animateSearchingOrganizations = false

    var body: some View {
        VStack {
            WrappingHeightScrollView {
                VStack(alignment: .leading) {
                    let inviteToAnotherOrg = viewModel.inviteToAnotherOrg
                    if !animateTopSearchBar {
                        Text(t.t("Invite new user via email invitation link"))
                            .fontHeader3()
                            .padding(.vertical, appTheme.listItemVerticalPadding)

                        RadioButton(
                            text: viewModel.myOrgInviteOptionText,
                            isSelected: !inviteToAnotherOrg
                        ) {
                            viewModel.inviteToAnotherOrg = false
                        }
                        .padding(.bottom, appTheme.listItemVerticalPadding)

                        RadioButton(
                            text: viewModel.anotherOrgInviteOptionText,
                            isSelected: inviteToAnotherOrg
                        ) {
                            viewModel.inviteToAnotherOrg = true
                        }
                    }

                    SuggestionsSearchField(
                        q: $viewModel.organizationNameQuery,
                        animateSearchFieldFocus: $animateTopSearchBar,
                        focusState: _focusState,
                        hint: t.t("profileOrg.organization_name")
                    )
                    .padding(.leading, animateSearchOrgLeadSpace)
                    .disabled(!inviteToAnotherOrg)
                    .onChange(of: animateTopSearchBar) { newValue in
                        withAnimation {
                            animateSearchOrgLeadSpace = newValue ? 0 : 24
                        }
                    }

                    if !animateTopSearchBar {
                        HStack(spacing: appTheme.gridItemSpacing) {
                            Image(systemName: "envelope")

                            TextField(t.t("invitationsVue.email"), text: $viewModel.inviteEmailAddresses)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($focusState, equals: TextInputFocused.anyTextInput)
                        }
                        .textFieldBorder()
                        .padding(.top, appTheme.listItemVerticalPadding * 2)

                        Text(t.t("~~Use commas if inviting multiple email addresses"))
                            .fontBodySmall()

                        Button {
                            viewModel.sendInvites()
                        } label: {
                            BusyButtonContent(
                                isBusy: viewModel.isSendingInvite,
                                text: t.t("inviteTeammates.send_invites")
                            )
                        }
                        .stylePrimary()
                        .padding(.vertical)

                        Spacer()
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .disabled(viewModel.editableView.disabled)
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(animateTopSearchBar)

            if animateTopSearchBar {
                ScrollView {
                    ForEach(viewModel.organizationsSearchResult) { organization in
                        Text(organization.name)
                            .onTapGesture {
                                viewModel.onSelectOrganization(organization)
                                focusState = nil
                                withAnimation {
                                    animateTopSearchBar = false
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: appTheme.rowItemHeight)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .onChange(of: viewModel.isSearchingOrganizations) { newValue in
                    animateSearchingOrganizations = newValue
                }
            }

            Spacer()

            if !animateTopSearchBar,
               focusableViewState.isFocused {
                OpenKeyboardActionsView()
            }
        }
        .onChange(of: focusState) { focusableViewState.focusState = $0 }

        if animateTopSearchBar,
           animateSearchingOrganizations {
            ProgressView()
        }
    }
}
