import SwiftUI

struct PasteOrgInviteView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: PasteOrgInviteViewModel

    @State private var invitationLink = ""

    var body: some View {
        ZStack {
            VStack(spacing: appTheme.listItemVerticalPadding) {
                Group {
                    Text(t.t("~~Paste invitation link below and accept the invite"))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let errorMessage = viewModel.inviteCodeError
                    if errorMessage.isNotBlank {
                        Text(errorMessage)
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, appTheme.listItemVerticalPadding)
                    }

                    TextField(t.t("~~Invitation link"), text: $invitationLink)
                        .textFieldBorder()
                        .onSubmit { viewModel.onSubmitLink(invitationLink) }
                        .padding(.bottom)
                }

                Button(t.t("~~Accept invite")) {
                    viewModel.onSubmitLink(invitationLink)
                }
                .stylePrimary()
                .disabled(viewModel.isVerifyingCode)

                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle(t.t("~~Invitation link"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onChange(of: viewModel.inviteCode) { newValue in
            router.openOrgUserInvite(newValue, popPath: true)
        }
    }
}
