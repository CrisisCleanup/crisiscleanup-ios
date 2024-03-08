import SwiftUI

struct VolunteerOrgView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: VolunteerOrgViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let getStartedInstruction = t.t("volunteerOrg.get_started_join_org")
                Text(getStartedInstruction)
                    .fontHeader2()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(appTheme.colors.separatorColor)
                    .accessibilityIdentifier("volunteerGetStartedText")

                InstructionTextAction(
                    instruction: t.t("volunteerOrg.click_inviation_link"),
                    actionText: t.t("volunteerOrg.paste_invitation_link"),
                    accessibilityIdentifier: "volunteerPasteLinkAction"
                ) {
                    router.openPasteOrgInviteLink()
                }
                .padding()

                StaticOrTextView()

                InstructionTextAction(
                    instruction: t.t("volunteerOrg.if_you_know_email"),
                    actionText: t.t("volunteerOrg.request_access"),
                    accessibilityIdentifier: "volunteerRequestAccessAction"
                ) {
                    router.openRequestOrgAccess()
                }
                .padding()

                StaticOrTextView()

                InstructionAction(
                    instruction: t.t("volunteerOrg.find_qr_code")
                ) {
                    Button {
                        router.openScanOrgQrCode()
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text(t.t("volunteerOrg.scan_qr_code"))
                        }
                    }
                    .stylePrimary()
                    .accessibilityIdentifier("volunteerScanQrCodeAction")
                }
                .padding()

                VStack(alignment: .leading) {
                    Text(t.t("volunteerOrg.if_no_account"))

                    Link(
                        t.t("registerOrg.register_org"),
                        destination: URL(string: "https://crisiscleanup.org/register")!
                    )
                    .accessibilityIdentifier("volunteerRegisterOrgAction")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(appTheme.colors.separatorColor)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(t.t("actions.sign_up"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct StaticOrTextView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        let orText = t.t("volunteerOrg.or")
        Text(orText)
            .frame(maxWidth: .infinity, alignment: .center)
            .fontHeader4()
            .foregroundColor(appTheme.colors.neutralFontColor)
            .listItemModifier()
            .background(appTheme.colors.separatorColor)
    }
}

private struct InstructionAction<Content>: View where Content: View {
    let instruction: String
    let content: Content

    init(
        instruction: String,
        @ViewBuilder contentView: () -> Content
    ) {
        self.instruction = instruction
        content = contentView()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(instruction)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
    }
}

private struct InstructionTextAction: View {
    let instruction: String
    let actionText: String
    let accessibilityIdentifier: String
    let onAction: () -> Void

    init(
        instruction: String,
        actionText: String,
        accessibilityIdentifier: String = "",
        onAction: @escaping () -> Void
    ) {
        self.instruction = instruction
        self.actionText = actionText
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onAction = onAction
    }

    var body: some View {
        InstructionAction(instruction: instruction) {
            Button(actionText) {
                onAction()
            }
            .stylePrimary()
            .accessibilityIdentifier(accessibilityIdentifier)
        }
    }
}
