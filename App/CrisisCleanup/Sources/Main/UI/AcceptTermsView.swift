import SwiftUI

struct AcceptTermsView: View {
    @Environment(\.translator) var t

    var termsUrl: URL
    var isLoading: Bool
    var onRequireCheckAcceptTerms: () -> Void
    var onRejectTerms: () -> Void = {}
    var onAcceptTerms: () -> Void = {}
    var errorMessage: String = ""

    @State private var showRejectTermsDialog = false
    @State private var isAcceptingTerms = false

    // TODO: List detail view
    var body: some View {
        VStack(alignment: .leading) {
            // TODO: Change background colors below accordingly

            Text(t.t("~~Using the Crisis Cleanup mobile app requires agreement with the following terms."))
                .listItemModifier()
                .accessibilityIdentifier("acceptTermsAgreeAgreementText")

            WebView(url: termsUrl)
                .accessibilityIdentifier("acceptTermsAgreement")

            if errorMessage.isNotBlank {
                Text(errorMessage)
                    .foregroundStyle(appTheme.colors.primaryRedColor)
                    .listItemModifier()
                    .accessibilityIdentifier("acceptTermsErrorMessage")
            }

            let linkText = "[\(termsUrl.absoluteString)](\(termsUrl.absoluteString))"
            let acceptText = t.t("~~I accept the terms of service from {terms_url}")
                .replacingOccurrences(of: "{terms_url}", with: linkText)
            let markdownString = try! AttributedString(markdown: acceptText)
            HStack(alignment: .top) {
                CheckboxImageView(isChecked: isAcceptingTerms)
                    .onTapGesture {
                        isAcceptingTerms.toggle()
                    }
                    .padding(.vertical, appTheme.gridItemSpacing)
                    .accessibilityIdentifier("acceptTermsAcceptToggle")
                Text(markdownString)
                    .accessibilityIdentifier("acceptTermsAcceptText")
            }
            .listItemModifier()

            HStack {
                Button(t.t("actions.reject")) {
                    showRejectTermsDialog = true
                }
                .styleCancel()
                .accessibilityIdentifier("acceptTermsRejectAction")

                Button(t.t("actions.save")) {
                    if !isAcceptingTerms {
                        onRequireCheckAcceptTerms()
                    } else {
                        onAcceptTerms()
                    }
                }
                .stylePrimary()
                .accessibilityIdentifier("acceptTermsAcceptAction")
            }
            .listItemModifier()
        }
        .disabled(isLoading)
        .sheet(
            isPresented: $showRejectTermsDialog,
            onDismiss: {
                showRejectTermsDialog = false
            }
        ) {
            VStack {
                Text(
                    t.t("~~Rejecting the terms of service will log you out from the app. You will not be able to use the app unless you log back in and accept the terms of service.")
                )
                .listItemModifier()
                .accessibilityIdentifier("rejectTermsConfirmText")

                HStack {
                    Button(t.t("actions.cancel")) {
                        showRejectTermsDialog = false
                    }
                    .styleCancel()
                    .accessibilityIdentifier("rejectTermsCancelAction")

                    Button(t.t("actions.reject")) {
                        onRejectTerms()
                    }
                    .stylePrimary()
                    .accessibilityIdentifier("rejectTermsConfirmRejectAction")
                }
                .listItemModifier()
            }
            .presentationDetents([.fraction(0.25), .medium])
        }
    }
}
