import SwiftUI

struct PasteOrgInviteView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: PasteOrgInviteViewModel

    @State private var invitationLink = ""
    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        VStack(spacing: appTheme.listItemVerticalPadding) {
            Text(t.t("pasteInvite.paste_invitation_link_and_accept"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("pasteOrgInviteText")

            let errorMessage = viewModel.inviteCodeError
            if errorMessage.isNotBlank {
                Text(errorMessage)
                    .foregroundColor(appTheme.colors.primaryRedColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, appTheme.listItemVerticalPadding)
                    .accessibilityIdentifier("pasteOrgInviteError")
            }

            TextField(t.t("pasteInvite.invite_link"), text: $invitationLink)
                .textFieldBorder()
                .focused($focusState, equals: .anyTextInput)
                .onSubmit { viewModel.onSubmitLink(invitationLink) }
                .padding(.bottom)
                .onAppear {
                    if invitationLink.isBlank {
                        focusState = .anyTextInput
                    }
                }
                .accessibilityIdentifier("pasteOrgInviteTextField")

            Button {
                viewModel.onSubmitLink(invitationLink)
            } label: {
                BusyButtonContent(
                    isBusy: viewModel.isVerifyingCode,
                    text: t.t("actions.accept_invite")
                )
            }
            .stylePrimary()
            .disabled(viewModel.isVerifyingCode)
            .accessibilityIdentifier("pasteOrgInviteSubmitAction")

            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle(t.t("nav.invitation_link"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onChange(of: viewModel.inviteCode) { newValue in
            router.openOrgUserInvite(newValue, popPath: true)
        }
    }
}
