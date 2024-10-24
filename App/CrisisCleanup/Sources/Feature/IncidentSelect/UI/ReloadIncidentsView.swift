import SwiftUI

struct ReloadIncidentsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var isRefreshingIncidents: Bool
    // TODO: Common dimensions
    var maxWidth: CGFloat = 300
    var onRetryLoad: () -> Void

    var body: some View {
        VStack {
            Spacer()
            // TODO: Edge case where no incidents are approved
            Text(t.t("info.incident_load_error"))
            // TODO: Common dimensions
            ZStack {}
                .frame(height: 16)
            HStack {
                Spacer()
                Button {
                    onRetryLoad()
                } label: {
                    Text(t.t("actions.retry"))
                        .padding(.horizontal)
                }
                .stylePrimary(true)
                .disabled(isRefreshingIncidents)
            }
            Spacer()
        }
        .frame(maxWidth: maxWidth)
    }
}
