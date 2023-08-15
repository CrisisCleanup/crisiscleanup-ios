import SwiftUI

struct CaseShareView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseShareViewModel

    @ObservedObject var focusableViewState = TextInputFocusableView()

    var body: some View {
        CaseShareNotSharableMessage(message: viewModel.notSharableMessage)
            .padding()

        WrappingHeightScrollView {
            VStack(alignment: .leading) {
                Text(t.t("casesVue.please_claim_if_share"))

                LargeTextEditor(text: $viewModel.unclaimedShareReason)
            }
            .padding(.horizontal)
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(focusableViewState)

        let disabled = !viewModel.isSharable

        if focusableViewState.isFocused {
            Spacer()

            OpenKeyboardActionsView()
        } else {
            VStack(spacing: appTheme.gridItemSpacing) {
                Button {
                    // Guarded by disabled below
                    router.openCaseShareStep2()
                } label: {
                    Text(t.t("actions.share_no_claim"))
                }
                .stylePrimary()
                .disabled(disabled || viewModel.unclaimedShareReason.isBlank)

                Button {
                    router.openCaseShareStep2()
                } label: {
                    Text(t.t("actions.claim_and_share"))
                }
                .stylePrimary()

                Button {
                    dismiss()
                } label: {
                    Text(t.t("actions.cancel"))
                }
                .styleCancel()
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

internal struct CaseShareNotSharableMessage: View {
    let message: String

    var body: some View {
        if message.isNotBlank {
            Text(message)
            // TODO: Common styles
                .foregroundColor(appTheme.colors.primaryRedColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
