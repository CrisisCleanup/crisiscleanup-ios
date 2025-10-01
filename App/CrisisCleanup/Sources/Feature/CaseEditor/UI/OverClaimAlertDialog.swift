import SwiftUI

struct OverClaimAlertDialog: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var onClose: () -> Void

    var body: some View {
        AlertDialog(
            title: t.t("info.claiming_restricted_threshold_exceeded_title"),
            positiveActionText: t.t("actions.ok"),
            negativeActionText: "",
            dismissDialog: onClose,
            positiveAction: onClose,
        ) {
            HtmlTextView(htmlContent: t.t("info.claiming_restricted_threshold_exceeded"))
                .padding()
        }
    }
}
