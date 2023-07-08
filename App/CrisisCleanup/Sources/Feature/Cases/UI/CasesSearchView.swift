import SwiftUI

struct CasesSearchView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CasesSearchViewModel

    var body: some View {
        let isLoading = viewModel.isLoading
        let isSelectingResult = viewModel.isSelectingResult
        let onCaseSelect = { result in viewModel.onSelectWorksite(result) }

        ZStack {
            VStack {
                // TODO: Style with border and padding
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        let buttonSize = 48.0
                        Image(systemName: "chevron.backward")
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    TextField(
                        t("actions.search"),
                        text: $viewModel.searchQuery
                    )
                    .autocapitalization(.none)
                    .padding([.vertical])
                    .disableAutocorrection(true)
                    .disabled(isSelectingResult)

                    Button {
                        router.openFilterCases()
                    } label: {
                        // TODO: Use component
                        Image("ic_dials", bundle: .module)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(appTheme.cornerRadius)
                    }
                }
                .overlay(
                    // TODO: Common color
                    RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                        .stroke(.gray, lineWidth: 1)
                )
                .padding()

                ScrollView {
                    if viewModel.searchQuery.isBlank {
                        RecentCasesView(
                            recents: viewModel.recentWorksites,
                            onSelect: onCaseSelect,
                            isEditable: !isSelectingResult)
                    } else {
                        if viewModel.searchResults.options.isNotEmpty {

                        } else {
                            let message = viewModel.searchResults.isShortQ ? t("info.search_query_is_short") : t("info.no_search_results").replacingOccurrences(of: "{search_string}", with: viewModel.searchResults.q)
                            Text(message)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            VStack {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onReceive(viewModel.$selectedWorksite) { (incidentId, worksiteId) in
            router.viewCase(incidentId: incidentId, worksiteId: worksiteId)
        }
    }
}

private struct RecentCasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let recents: [CaseSummaryResult]
    let onSelect: (CaseSummaryResult) -> Void
    let isEditable: Bool

    var body: some View {
        if recents.isNotEmpty {
            Text(t("casesVue.recently_viewed"))
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        ExistingWorksitesList(
            worksites: recents,
            onSelect: onSelect,
            isEditable: isEditable
        )
    }
}
