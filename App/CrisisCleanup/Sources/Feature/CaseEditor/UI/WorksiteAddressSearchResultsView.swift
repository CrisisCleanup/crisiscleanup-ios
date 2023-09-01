import SwiftUI

private struct ListItemTitle: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let textTranslateKey: String

    var body: some View {
        Text(t.t(textTranslateKey))
            .fontHeader3()
            .listItemModifier()
    }
}

internal struct WorksiteAddressSearchResultsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var isSearching: Bool
    @Binding var isShortQuery: Bool
    @Binding var locationQuery: String
    @Binding var results: LocationSearchResults

    let onCaseSelect: (CaseSummaryResult) -> Void
    let onAddressSelect: (KeySearchAddress) -> Void

    var body: some View {
        if isShortQuery {
            let instructions = t.t("caseForm.location_instructions")
            HtmlTextView(htmlContent: instructions)
                .padding()
        } else {
            let query = locationQuery.trim()

            if results.isEmpty {
                if !isSearching && results.query == query {
                    let text = t.t("worksiteSearchInput.no_location_results")
                        .replacingOccurrences(of: "{q}", with: query)
                    Text(text)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ScrollLazyVGrid {
                    if results.worksites.isNotEmpty {
                        ListItemTitle(textTranslateKey: "worksiteSearchInput.existing_cases")

                        ForEach(results.worksites, id: \.id) { worksite in
                            CaseView(worksite: worksite)
                                .onTapGesture {
                                    onCaseSelect(worksite)
                                }
                                .padding()
                        }
                    }

                    if results.addresses.isNotEmpty {
                        ListItemTitle(textTranslateKey: "caseView.full_address")

                        ForEach(results.addresses, id: \.key) { result in
                            AddressResultView(address: result)
                                .onTapGesture {
                                    onAddressSelect(result)
                                }
                                .padding()
                        }
                    }
                }
            }
        }
    }
}

private struct AddressResultView: View {
    let address: KeySearchAddress

    var body: some View {
        VStack(alignment: .leading) {
            Text(address.addressLine1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(address.addressLine2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
