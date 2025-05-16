import MapKit
import SwiftUI

struct CaseMoveOnMapView: View {
    @ObservedObject var viewModel: CaseChangeLocationAddressViewModel

    var body: some View {
        CaseMoveOnMapLayoutView()
            .environmentObject(viewModel)
    }
}

private struct CaseMoveOnMapLayoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewLayout: ViewLayoutDescription
    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    @ObservedObject private var focusableViewState = TextInputFocusableView()
    @State private var animateTopSearchBar = false

    @State var map = MKMapView()

    @FocusState private var focusState: TextInputFocused?

    @State private var showSearchingIndicator = false
    @State private var showOutOfBoundsAlert = false

    var body: some View {
        // TODO: Disable elements when uninterruptible operations are ongoing
        // let disabled = viewModel.isProcessingAction

        ZStack {
            if viewLayout.isListDetailLayout {
                GeometryReader { proxy in
                    HStack {
                        VStack {
                            SearchInputView(
                                hasInternetConnection: viewModel.hasInternetConnection,
                                animateTopSearchBar: $animateTopSearchBar,
                                locationQuery: $viewModel.locationQuery,
                                closeSearchBarTrigger: $viewModel.closeSearchBarTrigger,
                                focusState: _focusState
                            )

                            Spacer()

                            if !animateTopSearchBar {
                                UseMyLocationButton(useMyLocation: viewModel.useMyLocation)

                                MoveOnMapBottomActions(isVertical: true)
                            }
                        }
                        .frame(width: proxy.size.width * listDetailListFractionalWidth)

                        VStack {
                            if animateTopSearchBar {
                                SearchResultsView(showSearchingIndicator: $showSearchingIndicator)
                            } else {
                                OutOfBoundsMoveOnMapView()
                            }
                        }
                        .frame(width: proxy.size.width * listDetailDetailFractionalWidth)
                    }
                }
            } else {
                VStack {
                    SearchInputView(
                        hasInternetConnection: viewModel.hasInternetConnection,
                        animateTopSearchBar: $animateTopSearchBar,
                        locationQuery: $viewModel.locationQuery,
                        closeSearchBarTrigger: $viewModel.closeSearchBarTrigger,
                        focusState: _focusState
                    )

                    if animateTopSearchBar {
                        SearchResultsView(showSearchingIndicator: $showSearchingIndicator)
                    } else {
                        OutOfBoundsMoveOnMapView()

                        UseMyLocationButton(useMyLocation: viewModel.useMyLocation)

                        MoveOnMapBottomActions()
                    }
                }
            }

            if viewModel.showExplainLocationPermission {
                LocationAppSettingsDialog {
                    viewModel.showExplainLocationPermission = false
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
                    .presentationDetents([.fraction(0.40), .medium])
            } else {
                // Should never happen if state is consistent
                Text("A bug in the code")
            }
        }
        .screenTitle(t.t("caseForm.select_on_map"))
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
        .onChange(of: focusState) { focusableViewState.focusState = $0 }
    }
}

private struct SearchInputView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var hasInternetConnection: Bool

    @Binding var animateTopSearchBar: Bool
    @Binding var locationQuery: String
    @Binding var closeSearchBarTrigger: Bool

    var focusState: FocusState<TextInputFocused?>

    var body: some View {
        if hasInternetConnection {
            let hint = t.t("caseView.full_address")
            SuggestionsSearchField(
                q: $locationQuery,
                animateSearchFieldFocus: $animateTopSearchBar,
                focusState: focusState,
                hint: "\(hint) *",
                autocapitalization: .words
            )
            .onChange(of: closeSearchBarTrigger, perform: { _ in
                if locationQuery.isBlank {
                    animateTopSearchBar = false
                }
            })
            .padding(.horizontal)
            .padding(.top, appTheme.listItemVerticalPadding)
        }
    }
}
private struct SearchResultsView: View {
    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    @Binding var showSearchingIndicator: Bool

    var body: some View {
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
                        viewModel.onSearchAddressSelected($0)
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
}

private struct UseMyLocationButton: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var useMyLocation: () -> Void

    var body: some View {
        Button {
            useMyLocation()
        } label: {
            Image("ic_use_my_location", bundle: .module)
            Text(t.t("caseForm.use_my_location"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OutOfBoundsMoveOnMapView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    @State private var map = MKMapView()
    @State private var isLocationOutOfBounds = false

    var body: some View {
        let outOfBoundsMessage = viewModel.locationOutOfBoundsMessage
        MoveOnMapView(
            map: $map,
            targetCoordinates: $viewModel.mapCoordinates,
            isTargetOutOfBounds: $isLocationOutOfBounds,
            mapCenterMover: viewModel.mapCenterMover
        )
        .if (isLocationOutOfBounds) { view in
            view.overlay(alignment: .bottomLeading) {
                Text(outOfBoundsMessage)
                    .fontBodySmall()
                    .padding()
                    .background(.white.disabledAlpha())
                    .padding()
            }
        }
        .onChange(of: viewModel.locationOutOfBoundsMessage) { newValue in
            isLocationOutOfBounds = newValue.isNotBlank
        }
    }
}

private struct BottomActions: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    var body: some View {
        Button {
            dismiss()
        } label: {
            Text(t.t("actions.cancel"))
        }
        .styleCancel()

        Button {
             viewModel.onSaveMapMove()
        } label: {
            Text(t.t("actions.save"))
        }
        .stylePrimary()
    }
}

private struct MoveOnMapBottomActions: View {
    var isVertical = false

    var body: some View {
        if isVertical {
            // TODO: Common dimensions
            VStack(spacing: 24) {
                BottomActions()
            }
        } else {
            HStack{
                BottomActions()
            }
            .listItemModifier()
        }
    }
}
