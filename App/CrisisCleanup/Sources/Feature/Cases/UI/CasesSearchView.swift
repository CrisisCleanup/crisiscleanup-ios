import SwiftUI

struct CasesSearchView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CasesSearchViewModel

    @State private var isLoadingVisible = false

    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        let isLoading = viewModel.isLoading
        let isSearching = viewModel.isSearching
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
                        let buttonSize = appTheme.buttonSize
                        // TODO: Size is not consistent with other custom back images
                        Image(systemName: "chevron.backward")
                            .font(Font.system(size: 18, weight: .semibold))
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    TextField(
                        t.t("actions.search"),
                        text: $viewModel.searchQuery
                    )
                    .autocapitalization(.none)
                    .focused($focusState, equals: .anyTextInput)
                    .padding([.vertical])
                    .disableAutocorrection(true)
                    .disabled(disable)
                    .onChange(of: viewModel.focusOnSearchInput) { newValue in
                        if newValue {
                            focusState = .anyTextInput
                        }
                    }

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
                .roundedBorder()
                .padding()

                ScrollView {
                    if viewModel.searchQuery.isBlank {
                        RecentCasesView(
                            recents: viewModel.recentWorksites,
                            onSelect: onCaseSelect,
                            isEditable: isEditable
                        )
                    } else {
                        let searchResults = viewModel.searchResults.options
                        if searchResults.isNotEmpty {
                            ExistingWorksitesList(
                                worksites: searchResults,
                                onSelect: onCaseSelect,
                                isEditable: isEditable
                            )
                        } else if !isSearching {
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
                .scrollDismissesKeyboard(.immediately)
            }

            if isLoadingVisible {
                ProgressView()
            }
        }
        .background(SwipeBackGestureController())
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onReceive(viewModel.$selectedWorksite) { (incidentId, worksiteId) in
            router.viewCase(incidentId: incidentId, worksiteId: worksiteId)
        }
        .onChange(of: isLoading) { b in
            withAnimation {
                isLoadingVisible = b
            }
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
