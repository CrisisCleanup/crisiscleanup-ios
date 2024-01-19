import SwiftUI

struct ExplainWrongLocationDialog: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var showDialog: Bool

    var body: some View {
        Button {
            showDialog = true
        } label: {
            Image(systemName: "exclamationmark.triangle.fill")
                .tint(appTheme.colors.attentionBackgroundColor)
            // TODO: Common dimensions
                .frame(width: 36, height: 36)
        }
        .sheet(
            isPresented: $showDialog,
            onDismiss: { showDialog = false }
        ) {
            Text(t.t("flag.worksite_wrong_location_description"))
                .presentationDetents([.fraction(0.25), .medium])
        }
    }
}
