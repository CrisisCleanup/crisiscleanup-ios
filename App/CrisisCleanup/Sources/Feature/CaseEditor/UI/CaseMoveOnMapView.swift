import MapKit
import SwiftUI

struct CaseMoveOnMapView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseMoveOnMapViewModel

    private let focusableViewState = TextInputFocusableView()
    @State private var animateTopSearchBar = false

    @State var map = MKMapView()

    @FocusState private var focusState: TextInputFocused?

    @State private var showSearchingIndicator = false

    var body: some View {
        // TODO: Disable elements when uninterruptible operations are ongoing

        VStack {
            if viewModel.hasInternetConnection {
                let hint = t.t("caseView.full_address")
                SuggestionsSearchField(
                    q: $viewModel.locationQuery,
                    animateSearchFieldFocus: $animateTopSearchBar,
                    focusState: _focusState,
                    hint: "\(hint) *"
                )
                .onChange(of: viewModel.closeSearchBarTrigger, perform: { _ in
                    if viewModel.locationQuery.isBlank {
                        animateTopSearchBar = false
                    }
                })
                .padding([.horizontal, .top])
            }

            if animateTopSearchBar {
                ZStack {
                    VStack {
                        WorksiteAddressSearchResultsView(
                            isSearching: $viewModel.isLocationSearching,
                            isShortQuery: $viewModel.isShortQuery,
                            locationQuery: $viewModel.locationQuery,
                            results: $viewModel.searchResults,
                            onCaseSelect: {
                                viewModel.onExistingWorksiteSelected($0)
                                // TODO: Route to existing correctly
                            },
                            onAddressSelect: {
                                if viewModel.onGeocodeAddressSelected($0) {
                                    dismiss()
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
            } else {
                MoveOnMapView()

                MoveOnMapBottomActions()
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
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .onChange(of: focusState) { focusableViewState.focusState = $0 }
    }
}

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
    let onAddressSelect: (LocationAddress) -> Void

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
                            AddressResultView(address: result.address)
                                .onTapGesture {
                                    onAddressSelect(result.address)
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
    let address: LocationAddress

    var body: some View {
        VStack(alignment: .leading) {
            Text(address.address)
                .frame(maxWidth: .infinity, alignment: .leading)

            let secondLine = [
                address.city,
                address.state,
                address.country
            ].combineTrimText()
            Text(secondLine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoveOnMapView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseMoveOnMapViewModel

    @State private var map = MKMapView()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MoveOnMapMapView(
                map: $map,
                caseCoordinates: $viewModel.mapCoordinates,
                viewModel: viewModel
            )

            // TODO: Out of bounds message
        }

        Button {
            viewModel.useMyLocation()
        } label: {
            Image("ic_use_my_location", bundle: .module)
            Text(t.t("caseForm.use_my_location"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoveOnMapBottomActions: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseMoveOnMapViewModel

    var body: some View {
        HStack{
            Button {
                dismiss()
            } label: {
                Text(t.t("actions.cancel"))
            }
            .styleCancel()

            Button {
                viewModel.onSave()
            } label: {
                Text(t.t("actions.save"))
            }
            .stylePrimary()
        }
        .listItemModifier()
    }
}

private class MoveOnMapCoordinator: NSObject, MKMapViewDelegate {
    let viewModel: CaseMoveOnMapViewModel

    init(viewModel: CaseMoveOnMapViewModel) {
        self.viewModel = viewModel
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        overlayMapRenderer(overlay as! MKPolygon)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.staticMapAnnotationView(annotation)
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//        imgView.center = mapView.center
//        imgView.center.y = imgView.center.y - (imgView.image?.size.height ?? 0)/2
//
//        mapView.addSubview(imgView)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // TODO: Report back to view model to adjust the coordinates
        //        (mapView.region.span.longitudeDelta * 128))
//        viewModel.onMapCameraChange(zoom, mapView.region, animated)
    }
}

private struct MoveOnMapMapView : UIViewRepresentable {
    @Binding var map: MKMapView
    @Binding var caseCoordinates: CLLocationCoordinate2D

    @ObservedObject var viewModel: CaseMoveOnMapViewModel

    func makeUIView(context: Context) -> MKMapView {
        map.configureStaticMap()

        map.delegate = context.coordinator

        let image = UIImage(named: "cc_map_pin", in: .module, with: .none)!
        let casePin = CustomPinAnnotation(caseCoordinates, image)
        map.addAnnotation(casePin)
        map.showAnnotations([casePin], animated: false)

        return map
    }

    func makeCoordinator() -> MoveOnMapCoordinator {
        MoveOnMapCoordinator(viewModel: viewModel)
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MoveOnMapMapView>) {
        if let annotation = uiView.annotations.firstOrNil,
           let pinAnnotation = annotation as? CustomPinAnnotation {
            pinAnnotation.coordinate = caseCoordinates

            uiView.animaiteToCenter(caseCoordinates)
        }
    }
}
