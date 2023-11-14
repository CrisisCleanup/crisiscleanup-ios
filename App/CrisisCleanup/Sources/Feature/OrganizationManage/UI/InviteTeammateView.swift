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
                            disableAutocorrect: true
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
                                    return "~~This organization does not yet have an account. We will create an account and contact this person to finalize the registration."
                                } else if viewModel.inviteOrgState.nonAffiliate {
                                    return "~~This user will need to be approved by somebody from the organization."
                                }
                                return ""
                            }()
                            if messageKey.isNotBlank {
                                Text(t.t(messageKey))
                                    .foregroundColor(appTheme.colors.primaryBlueColor)
                            }
                        }
                    }
                    .padding(.leading, animateSearchOrgLeadSpace)
                    .padding(.bottom)

                    if !animateTopSearchBar {
                        if viewModel.emailAddressErrorMessage.isNotBlank {
                            Text(viewModel.emailAddressErrorMessage)
                                .foregroundColor(appTheme.colors.primaryRedColor)
                        }

                        HStack(spacing: appTheme.gridItemSpacing) {
                            Image(systemName: "envelope")

                            TextField(t.t("invitationsVue.email"), text: $viewModel.inviteEmailAddresses)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($focusState, equals: TextInputFocused.anyTextInput)
                        }
                        .textFieldBorder()

                        Group {
                            if isNewOrganization {
                                HStack(spacing: appTheme.gridItemSpacing) {
                                    Image(systemName: "phone.fill")

                                    TextField(t.t("~~Cell Phone (optional but really helpful)"), text: $viewModel.invitePhoneNumber)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .focused($focusState, equals: TextInputFocused.anyTextInput)
                                }
                                .textFieldBorder()
                            } else {
                                Text(t.t("~~Use commas if inviting multiple email addresses"))
                                    .fontBodySmall()
                            }
                        }
                        .padding(.bottom)

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
                        .padding(.bottom)

                        if viewModel.inviteOrgState.ownOrAffiliate,
                           viewModel.scanQrCodeText.isNotBlank {
                            let orText = t.t("~~Or")
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
                                        Text(t.t("~~We are having issues with organization invite codes."))
                                            .padding(.vertical)
                                    }
                                }
                            }
                        }

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
        .onChange(of: focusState) { focusableViewState.focusState = $0 }

        if animateTopSearchBar,
           animateSearchingOrganizations {
            ProgressView()
        }
    }
}

private struct SuggestedOrganizationsView: View {
    @EnvironmentObject var viewModel: InviteTeammateViewModel

    @Binding var animateTopSearchBar: Bool
    @Binding var animateSearchingOrganizations: Bool
    var focusState: FocusState<TextInputFocused?>.Binding

    var body: some View {
        ScrollView {
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