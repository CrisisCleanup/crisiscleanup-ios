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
        let disable = isSelectingResult
        let isEditable = !isSelectingResult

        ZStack {
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        let buttonSize = 48.0
                        Image(systemName: "chevron.backward")
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    TextField(
                        t.t("actions.search"),
                        text: $viewModel.searchQuery
                    )
                    .autocapitalization(.none)
                    .padding([.vertical])
                    .disableAutocorrection(true)
                    .disabled(disable)

                    if viewModel.searchQuery.isNotBlank {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark")
                                .background(Color.white)
                                .foregroundColor(Color.black)
                        }
                        .disabled(disable)
                        .padding()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                        .stroke(appTheme.colors.unfocusedBorderColor, lineWidth: 1)
                )
                .padding()

                // TODO: LazyVStack
                ScrollView {
                    if viewModel.searchQuery.isBlank {
                        RecentCasesView(
                            recents: viewModel.recentWorksites,
                            onSelect: onCaseSelect,
                            isEditable: isEditable)
                    } else {
                        let searchResults = viewModel.searchResults.options
                        if searchResults.isNotEmpty {
                            ExistingWorksitesList(
                                worksites: searchResults,
                                onSelect: onCaseSelect,
                                isEditable: isEditable
                            )
                        } else {
                            let message = viewModel.searchResults.isShortQ
                            ? t.t("info.search_query_is_short")
                            : t.t("info.no_search_results")
                                .replacingOccurrences(
                                    of: "{search_string}",
                                    with: viewModel.searchResults.q
                                )
                            Text(message)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            // TODO: Is container necessary? Animate.
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
            Text(t.t("casesVue.recently_viewed"))
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
