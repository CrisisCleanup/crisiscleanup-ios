import SwiftUI

struct CaseShareView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseShareViewModel

    @State var tempString = ""

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(t.t("casesVue.please_claim_if_share"))
                Spacer()
            }

            LargeTextEditor(text: $tempString)
                .padding(.bottom, 4)

            Button {
                // share without claiming
            } label: {
                Text(t.t("actions.share_no_claim"))
            }
            .stylePrimary()
            .disabled(tempString.isBlank)
            .padding(.bottom, 4)

            Button {
                // share without claiming
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
    }
}
