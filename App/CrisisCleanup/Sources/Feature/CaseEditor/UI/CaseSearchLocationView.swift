import SwiftUI

struct CaseSearchLocationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseChangeLocationAddressViewModel

    @State private var showSearchingIndicator = false
    @State private var showOutOfBoundsAlert = false

    var body: some View {
        VStack {
            if viewModel.hasInternetConnection {
                let hint = t.t("caseView.full_address")
                TextField("\(hint) *", text: $viewModel.locationQuery)
                    .textFieldBorder()
                    .padding([.horizontal, .top])
            }

            ZStack {
                VStack {
                    WorksiteAddressSearchResultsView(
                        isSearching: $viewModel.isLocationSearching,
                        isShortQuery: $viewModel.isShortQuery,
                        locationQuery: $viewModel.locationQuery,
                        results: $viewModel.searchResults,
                        onCaseSelect: {
                            viewModel.onExistingWorksiteSelected($0)
                        },
                        onAddressSelect: {
                            if viewModel.onGeocodeAddressSelected($0) {
                                viewModel.commitChanges()
                            }
                        }
                    )

                    Spacer()
                }

                if showSearchingIndicator {
                    ProgressView()
                        .padding(48)
                }
            }
        }
        .onReceive(viewModel.$locationOutOfBounds) { data in
            showOutOfBoundsAlert = data != nil
        }
        .sheet(isPresented: $showOutOfBoundsAlert) {
            if let outOfBoundsData = viewModel.locationOutOfBounds {
                LocationOutOfBoundsAlert(outOfBoundsData: outOfBoundsData)
                    .interactiveDismissDisabled()
                    .presentationDetents([.medium])
            } else {
                // Should never happen if state is consistent
                Text("A bug in the code")
            }
        }
        .screenTitle(t.t("formLabels.location"))
        .onChange(of: viewModel.isLocationSearching) { isSearching in
            withAnimation {
                showSearchingIndicator = isSearching
            }
        }
        .onChange(of: viewModel.editIncidentWorksite) { identifier in
            if identifier != ExistingWorksiteIdentifierNone {
                router.viewCase(
                    incidentId: identifier.incidentId,
                    worksiteId: identifier.worksiteId,
                    popToRoot: true
                )
            }
        }
        .onChange(of: viewModel.isLocationCommitted) { newValue in
            if newValue {
                dismiss()
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}
