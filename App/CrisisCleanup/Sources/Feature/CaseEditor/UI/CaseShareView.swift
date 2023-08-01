import SwiftUI

struct CaseShareView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseShareViewModel

    var body: some View {
        // TODO: Disable actions if not online
        VStack(alignment: .leading) {
            HStack {
                Text(t.t("casesVue.please_claim_if_share"))
                Spacer()
            }

            LargeTextEditor(text: $viewModel.unclaimedShareReason)
                .padding(.bottom, 4)

            Button {
                // Guarded by disabled below
                router.openCaseShareStep2()
            } label: {
                Text(t.t("actions.share_no_claim"))
            }
            .stylePrimary()
            .disabled(viewModel.unclaimedShareReason.isBlank)
            .padding(.bottom, 4)

            Button {
                router.openCaseShareStep2()
            } label: {
                Text(t.t("actions.claim_and_share"))
            }
            .stylePrimary()
            .padding(.bottom, 4)

            Button {
                // share without claiming
            } label: {
                Text(t.t("actions.cancel"))
            }
            .styleCancel()

            Spacer()
        }
        .padding(.horizontal)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
