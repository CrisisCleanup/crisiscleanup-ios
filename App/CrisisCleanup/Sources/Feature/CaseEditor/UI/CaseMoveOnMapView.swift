import MapKit
import SwiftUI

struct CaseMoveOnMapView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseChangeLocationAddressViewModel

    private let focusableViewState = TextInputFocusableView()
    @State private var animateTopSearchBar = false

    @State var map = MKMapView()

    @FocusState private var focusState: TextInputFocused?

    @State private var showSearchingIndicator = false
    @State private var showOutOfBoundsAlert = false

    var body: some View {
        // TODO: Disable elements when uninterruptible operations are ongoing
        let disabled = viewModel.isProcessingAction

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
            } else {
                MoveOnMapView()

                MoveOnMapBottomActions()
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
                // Should never show if state is consistent
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
        .environmentObject(viewModel)
        .onChange(of: focusState) { focusableViewState.focusState = $0 }
    }
}

private struct MoveOnMapView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    @State private var map = MKMapView()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let outOfBoundsMessage = viewModel.locationOutOfBoundsMessage
            MoveOnMapMapView(
                map: $map,
                caseCoordinates: $viewModel.mapCoordinates,
                viewModel: viewModel
            )
            .if(outOfBoundsMessage.isNotBlank) { view in
                view.overlay(alignment: .bottomLeading) {
                    Text(outOfBoundsMessage)
                        .fontBodySmall()
                        .padding()
                        .background(.white.disabledAlpha())
                        .padding()
                }
            }
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

    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    var body: some View {
        HStack{
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
        .listItemModifier()
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

    @ObservedObject var viewModel: CaseChangeLocationAddressViewModel

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
