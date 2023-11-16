import SwiftUI

struct VolunteerOrgView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: VolunteerOrgViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let getStartedInstruction = t.t("~~To get started you need to join an organization. There are three ways to join.")
                Text(getStartedInstruction)
                    .fontHeader2()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(appTheme.colors.separatorColor)

                InstructionTextAction(
                    instruction: t.t("~~Click on the invitation link in an email invite. If nothing happens"),
                    actionText: t.t("~~Paste invitation link"),
                    onAction: {
                     router.openPasteOrgInviteLink()
                })
                .padding()

                StaticOrTextView()

                InstructionTextAction(
                    instruction: t.t("~~If you know an email of someone in your organization who already has an account."),
                    actionText: t.t("nav.request_access"),
                    onAction: {
                     router.openRequestOrgAccess()
                })
                .padding()

                StaticOrTextView()

                InstructionAction(
                    instruction: t.t("~~Find someone with an invitation QR code.")
                ) {
                    Button {
                         router.openScanOrgQrCode()
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text(t.t("Scan QR code"))
                        }
                    }
                    .stylePrimary()
                }
                .padding()

                VStack(alignment: .leading) {
                    Text(t.t("~~If your organization does not have an account:"))

                    Link(
                        t.t("registerOrg.register_org"),
                        destination: URL(string: "https://crisiscleanup.org/register")!
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(appTheme.colors.separatorColor)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(t.t("~~Signup"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct StaticOrTextView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        let orText = t.t("~~Or")
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
    let onAction: () -> Void

    init(
        instruction: String,
        actionText: String,
        onAction: @escaping () -> Void
    ) {
        self.instruction = instruction
        self.actionText = actionText
        self.onAction = onAction
    }

    var body: some View {
        InstructionAction(instruction: instruction) {
            Button(actionText) {
                onAction()
            }
            .stylePrimary()
        }
    }
}
