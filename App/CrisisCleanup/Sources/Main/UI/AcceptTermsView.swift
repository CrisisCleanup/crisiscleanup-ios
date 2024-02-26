import SwiftUI

struct AcceptTermsView: View {
    @Environment(\.translator) var t

    var termsUrl: URL
    var privacyUrl: URL
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

            Text(t.t("termsConditionsModal.must_agree_to_use_ccu"))
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

            let termsAbsoluteUrl = termsUrl.absoluteString
            let privacyAbsoluteUrl = privacyUrl.absoluteString
            let acceptText = t.t("termsConditionsModal.accept_toc_privacy")
                .replacingOccurrences(of: "{terms_url}", with: termsAbsoluteUrl)
                .replacingOccurrences(of: "{privacy_url}", with: privacyAbsoluteUrl)
            HStack(alignment: .top) {
                CheckboxImageView(isChecked: isAcceptingTerms)
                    .onTapGesture {
                        isAcceptingTerms.toggle()
                    }
                    .padding(.vertical, appTheme.gridItemSpacing)
                    .accessibilityIdentifier("acceptTermsAcceptToggle")
                HtmlTextView(htmlContent: acceptText)
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
            VStack(alignment: .leading) {
                Text(t.t("termsConditionsModal.are_you_sure"))
                    .fontHeader3()
                    .padding()

                Text(t.t("termsConditionsModal.if_reject_cannot_use"))
                    .listItemModifier()
                    .accessibilityIdentifier("rejectTermsConfirmText")

                Spacer()

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
            .presentationDetents([.fraction(0.33), .medium])
        }
    }
}
