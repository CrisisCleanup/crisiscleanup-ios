import MapKit
import SwiftUI

struct CaseMoveOnMapView: View {
    @ObservedObject var viewModel: CaseChangeLocationAddressViewModel

    var body: some View {
        GeometryReader { geometry in
            CaseMoveOnMapLayoutView(viewLayout: ViewLayoutDescription(geometry.size))
                .environmentObject(viewModel)
        }
    }
}

private struct CaseMoveOnMapLayoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    var viewLayout = ViewLayoutDescription()

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
                                MoveOnMapView()
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
                        MoveOnMapView()

                        UseMyLocationButton(useMyLocation: viewModel.useMyLocation)

                        MoveOnMapBottomActions()
                    }
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
                    .presentationDetents([.fraction(0.33), .medium])
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
                hint: "\(hint) *"
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

private struct MoveOnMapView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    @State private var map = MKMapView()

    var body: some View {
        let outOfBoundsMessage = viewModel.locationOutOfBoundsMessage
        MoveOnMapMapView(
            map: $map,
            caseCoordinates: $viewModel.mapCoordinates,
            viewModel: viewModel
        )
        .if (outOfBoundsMessage.isNotBlank) { view in
            view.overlay(alignment: .bottomLeading) {
                Text(outOfBoundsMessage)
                    .fontBodySmall()
                    .padding()
                    .background(.white.disabledAlpha())
                    .padding()
            }
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

private class MoveOnMapCoordinator: NSObject, MKMapViewDelegate {
    let viewModel: CaseChangeLocationAddressViewModel

    init(viewModel: CaseChangeLocationAddressViewModel) {
        self.viewModel = viewModel
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        overlayMapRenderer(overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.staticMapAnnotationView(annotation)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel.onMapChange(mapView.centerCoordinate)
    }
}

private struct MoveOnMapMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var caseCoordinates: CLLocationCoordinate2D

    @ObservedObject var viewModel: CaseChangeLocationAddressViewModel

    // TODO: Crossing incident bounds causes makeUIView to be called when the map already exists? Solve and remove guards in method below.
    //       Likely due to the conditional overlay.
    func makeUIView(context: Context) -> MKMapView {
        map.configure(
            isScrollEnabled: true,
            isExistingMap: map.annotations.isNotEmpty
        )

        map.delegate = context.coordinator

        if map.annotations.isEmpty {
            let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
            let casePin = CustomPinAnnotation(caseCoordinates, image)
            map.addAnnotation(casePin)
            map.showAnnotations([casePin], animated: false)
        }

        return map
    }

    func makeCoordinator() -> MoveOnMapCoordinator {
        MoveOnMapCoordinator(viewModel: viewModel)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MoveOnMapMapView>) {
        if let annotation = uiView.annotations.firstOrNil,
           let pinAnnotation = annotation as? CustomPinAnnotation {
            if viewModel.isPinCenterScreen {
                UIView.animate(withDuration: 0.3) {
                    pinAnnotation.coordinate = caseCoordinates
                }
            } else {
                pinAnnotation.coordinate = caseCoordinates

                uiView.animaiteToCenter(caseCoordinates)
            }
        }
    }
}
