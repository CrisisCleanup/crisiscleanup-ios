import SwiftUI

struct InviteTeammateView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: InviteTeammateViewModel

    @ObservedObject var focusableViewState = TextInputFocusableView()

    @State private var animateLoading = false

    var body: some View {
        ZStack {
            if animateLoading {
                ProgressView()
            } else if viewModel.isInviteSent {
                VStack {
                    RegisterSuccessView(
                        title: viewModel.inviteSentTitle,
                        message: viewModel.inviteSentText
                    )
                }
            } else if viewModel.hasValidTokens {
                InviteTeammateContentView()
            } else {
                // TODO: Style accordingly
                VStack{
                    Text(t.t("inviteTeammates.sign_in_to_invite"))
                        .fontHeader2()
                        .listItemModifier()

                    Spacer()
                }
            }
        }
        .hideNavBarUnderSpace()
        .screenTitle(t.t("nav.invite_teammates"))
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
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        let inviteToAnotherOrg = viewModel.inviteToAnotherOrg
                        if !animateTopSearchBar {
                            Text(t.t("inviteTeammates.invite_new_user_via_email"))
                                .fontHeader4()
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
                            .onChange(of: viewModel.inviteToAnotherOrg) { newValue in
                                if newValue,
                                   viewModel.organizationNameQuery.isBlank {
                                    focusState = .querySuggestions
                                }
                            }
                        }

                        let isNewOrganization = viewModel.inviteOrgState.new

                        VStack {
                            SuggestionsSearchField(
                                q: $viewModel.organizationNameQuery,
                                animateSearchFieldFocus: $animateTopSearchBar,
                                focusState: _focusState,
                                hint: t.t("profileOrg.organization_name"),
                                disableAutocorrect: true,
                                autocapitalization: .words
                            ) {
                                viewModel.onOrgQueryClose()
                            }
                            .disabled(!inviteToAnotherOrg)
                            .onChange(of: animateTopSearchBar) { newValue in
                                withAnimation {
                                    animateSearchOrgLeadSpace = newValue ? 0 : 24
                                }
                            }

                            if !animateTopSearchBar,
                               inviteToAnotherOrg {
                                let messageKey: String = {
                                    if isNewOrganization {
                                        return "inviteTeammates.org_does_not_have_account"
                                    } else if viewModel.inviteOrgState.nonAffiliate {
                                        // TODO: Update once logic is decided
                                        // return "inviteTeammates.user_needs_approval_from_org"
                                    }
                                    return ""
                                }()
                                if messageKey.isNotBlank {
                                    Text(t.t(messageKey))
                                        .foregroundColor(appTheme.colors.primaryBlueColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.leading, animateSearchOrgLeadSpace)
                        .padding(.bottom)

                        if !animateTopSearchBar {
                            if viewModel.emailAddressError.isNotBlank {
                                Text(viewModel.emailAddressError)
                                    .foregroundColor(appTheme.colors.primaryRedColor)
                            }

                            if viewModel.inviteOrgState.nonAffiliate {
                                Text(t.t("inviteTeammates.no_unaffiliated_invitations_allowed"))
                                    .foregroundColor(appTheme.colors.primaryBlueColor)

                            } else {
                                HStack(spacing: appTheme.gridItemSpacing) {
                                    Image(systemName: "envelope")

                                    TextField(t.t("invitationsVue.email"), text: $viewModel.inviteEmailAddresses)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .focused($focusState, equals: TextInputFocused.userEmailAddress)
                                        .onSubmit {
                                            if isNewOrganization {
                                                focusState = .userPhone
                                            }
                                        }
                                }
                                .textFieldBorder()

                                Group {
                                    if isNewOrganization {
                                        NewOrganizationInputView(
                                            focusState: $focusState
                                        )
                                        .padding(.top, appTheme.listItemVerticalPadding)
                                    } else {
                                        Text(t.t("inviteTeammates.use_commas_multiple_emails"))
                                            .fontBodySmall()
                                    }
                                }
                                .padding(.bottom)
                            }

                            if viewModel.sendInviteErrorMessage.isNotBlank {
                                Text(viewModel.sendInviteErrorMessage)
                                    .foregroundColor(appTheme.colors.primaryRedColor)
                            }

                            Button {
                                viewModel.sendInvites()
                            } label: {
                                BusyButtonContent(
                                    isBusy: viewModel.isSendingInvite,
                                    text: t.t("inviteTeammates.send_invites")
                                )
                            }
                            .stylePrimary()
                            .disabled(viewModel.inviteOrgState.nonAffiliate)
                            .padding(.bottom)

                            if viewModel.inviteOrgState.ownOrAffiliate,
                               viewModel.scanQrCodeText.isNotBlank {
                                let orText = t.t("inviteTeammates.or")
                                Text(orText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .fontHeader4()
                                    .foregroundColor(appTheme.colors.neutralFontColor)
                                    .padding(.bottom)

                                Text(viewModel.scanQrCodeText)
                                    .fontHeader4()

                                if viewModel.isGeneratingQrCode {
                                    HStack {
                                        ProgressView()
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    if viewModel.inviteToAnotherOrg {
                                        if let qrCode = viewModel.affiliateOrgQrCode {
                                            CenteredRowImage(image: qrCode)
                                        }
                                    } else {
                                        if let qrCode = viewModel.myOrgInviteQrCode {
                                            CenteredRowImage(image: qrCode)
                                        } else {
                                            Text(t.t("inviteTeammates.invite_error"))
                                                .padding(.vertical)
                                        }
                                    }
                                }
                            }

                            Spacer()
                        }
                    }
                    .frame(maxWidth: appTheme.contentMaxWidth, alignment: .leading)
                    .padding(.horizontal)
                    .disabled(viewModel.editableView.disabled)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(animateTopSearchBar)

            if animateTopSearchBar {
                SuggestedOrganizationsView(
                    animateTopSearchBar: $animateTopSearchBar,
                    animateSearchingOrganizations: $animateSearchingOrganizations,
                    focusState: $focusState
                )
            }

            Spacer()

            if !animateTopSearchBar,
               focusableViewState.isFocused {
                OpenKeyboardActionsView()
            }
        }
        .onChange(of: viewModel.errorFocus) { newValue in
            if let errorFocus = newValue {
                focusState = errorFocus
            }
        }
        .onChange(of: focusState) {
            focusableViewState.focusState = $0
            viewModel.errorFocus = nil
        }

        if animateTopSearchBar,
           animateSearchingOrganizations {
            ProgressView()
        }
    }
}

private struct UserInfoErrorText: View {
    let message: String

    var body: some View {
        if message.isNotBlank {
            Text(message)
                .foregroundColor(appTheme.colors.primaryRedColor)
        }
    }
}

private struct NewOrganizationInputView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: InviteTeammateViewModel

    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        // TODO: Set to equivalent of .padding not a multiple of custom padding
        VStack(alignment: .leading, spacing: appTheme.listItemVerticalPadding * 2) {
            Group {
                UserInfoErrorText(message: viewModel.phoneNumberError)
                HStack(spacing: appTheme.gridItemSpacing) {
                    Image(systemName: "phone.fill")

                    TextField(t.t("invitationSignup.mobile_placeholder"), text: $viewModel.invitePhoneNumber)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused(focusState, equals: TextInputFocused.userPhone)
                        .onSubmit { focusState.wrappedValue = .userFirstName }
                }
                .textFieldBorder()
            }

            Group {
                UserInfoErrorText(message: viewModel.firstNameError)
                TextField(t.t("invitationSignup.first_name_placeholder"), text: $viewModel.inviteFirstName)
                    .textFieldBorder()
                    .autocapitalization(.words)
                    .focused(focusState, equals: TextInputFocused.userFirstName)
                    .onSubmit { focusState.wrappedValue = .userLastName }
            }

            Group {
                UserInfoErrorText(message: viewModel.lastNameError)
                TextField(t.t("invitationSignup.last_name_placeholder"), text: $viewModel.inviteLastName)
                    .textFieldBorder()
                    .autocapitalization(.words)
                    .focused(focusState, equals: TextInputFocused.userLastName)
            }

            UserInfoErrorText(message: viewModel.selectedIncidentError)
            if viewModel.incidents.isNotEmpty {
                let selectedIncident = viewModel.incidentLookup[viewModel.selectedIncidentId] ?? EmptyIncident
                Menu {
                    Picker(selection: $viewModel.selectedIncidentId, label: Text("")) {
                        ForEach(viewModel.incidents, id: \.id) { incident in
                            Text(incident.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedIncident.name)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .textFieldBorder()
                }
                .buttonStyle(.plain)
            } else {
                ReloadIncidentsView(
                    isRefreshingIncidents: viewModel.isLoadingIncidents,
                    maxWidth: .infinity
                ) {
                    viewModel.refreshIncidents()
                }
            }
        }
    }
}

private struct SuggestedOrganizationsView: View {
    @EnvironmentObject var viewModel: InviteTeammateViewModel

    @Binding var animateTopSearchBar: Bool
    @Binding var animateSearchingOrganizations: Bool
    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        ScrollCenterContent {
            ForEach(viewModel.organizationsSearchResult) { organization in
                Text(organization.name)
                    .onTapGesture {
                        viewModel.onSelectOrganization(organization)
                        focusState.wrappedValue = nil
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
}

private struct CenteredRowImage: View {
    var image: UIImage
    var imageMaxSize: CGFloat = 240

    var body: some View {
        HStack {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: imageMaxSize)
        }
        .frame(maxWidth: .infinity)
    }
}
