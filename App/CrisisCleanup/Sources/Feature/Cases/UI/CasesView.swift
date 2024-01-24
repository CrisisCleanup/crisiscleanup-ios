import Foundation
import MapKit
import SVGView
import SwiftUI

struct CasesView: View {
    @ObservedObject var viewModel: CasesViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    var body: some View {
        GeometryReader { geometry in
            CasesLayoutView(
                viewLayout: ViewLayoutDescription(geometry.size),
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen
            )
            .environmentObject(viewModel)
        }
    }
}

struct CasesLayoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CasesViewModel

    var viewLayout = ViewLayoutDescription()

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    @State var map = MKMapView()
    @State private var showMapBusyIndicator = false

    func animateToSelectedIncidentBounds(_ bounds: LatLngBounds) {
        let latDelta = bounds.northEast.latitude - bounds.southWest.latitude
        let longDelta = bounds.northEast.longitude - bounds.southWest.longitude
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)

        let center = bounds.center
        let regionCenter = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude), span: span)
        let region = map.regionThatFits(regionCenter)
        map.setRegion(region, animated: true)
    }

    var body: some View {
        let hasNoIncidents = viewModel.incidentsData.incidents.isEmpty

        ZStack {
            if viewModel.isTableView {
                CasesTableView(
                    incidentSelectViewBuilder: incidentSelectViewBuilder,
                    hasNoIncidents: hasNoIncidents
                )
            } else {
                CasesMapView(
                    map: $map,
                    focusWorksiteCenter: $viewModel.editedWorksiteLocation,
                    viewModel: viewModel,
                    onSelectWorksite: { worksiteId in
                        let incidentId = viewModel.incidentsData.selectedId
                        router.viewCase(incidentId: incidentId, worksiteId: worksiteId)
                    }
                )
                .onReceive(viewModel.$incidentLocationBounds) { bounds in
                    animateToSelectedIncidentBounds(bounds.bounds)
                }
                .onReceive(viewModel.$mapMarkersChangeSet) { changes in
                    if changes.isClean {
                        let annotations = map.annotations
                        map.removeAnnotations(annotations)
                    }
                    map.addAnnotations(changes.newAnnotations)

                    viewModel.onAddMapAnnotations(changes)
                }
                .onChange(of: viewModel.isMyLocationEnabled) { enabled in
                    if enabled {
                        map.userTrackingMode = .follow
                    }
                }
            }

            if viewModel.showDataProgress {
                VStack {
                    ProgressView(value: viewModel.dataProgress, total: 1)
                        .progressViewStyle(
                            LinearProgressViewStyle(tint: appTheme.colors.primaryOrangeColor)
                        )

                    Spacer()
                }
            }

            if !viewModel.isTableView {
                if showMapBusyIndicator {
                    ProgressView()
                }
            }

            CasesOverlayElements(
                openAuthScreen: openAuthScreen,
                map: $map,
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                hasNoIncidents: hasNoIncidents,
                animateToSelectedIncidentBounds: animateToSelectedIncidentBounds,
                isShortScreen: viewLayout.isShort
            )

            if viewModel.showExplainLocationPermission {
                LocationAppSettingsDialog {
                    viewModel.showExplainLocationPermission = false
                }
            }
        }
        .onChange(of: viewModel.isMapBusy) { isBusy in
            withAnimation {
                showMapBusyIndicator = isBusy
            }
        }
        .onAppear {
            viewModel.onViewAppear()
            map.selectedAnnotations = []
        }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct MapViewTopActions: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CasesViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    let hasNoIncidents: Bool

    @State private var openIncidentSelect = false

    @State private var showCountProgress = false

    var body: some View {
        HStack {
            Button {
                openIncidentSelect.toggle()
            } label: {
                IncidentDisasterImage(
                    viewModel.incidentsData.selected,
                    disabled: hasNoIncidents,
                    background: .white
                )
                .shadow(radius: appTheme.shadowRadius)
            }
            .sheet(
                isPresented: $openIncidentSelect,
                onDismiss: {
                    incidentSelectViewBuilder.onIncidentSelectDismiss()
                }
            ) {
                incidentSelectViewBuilder.incidentSelectView(
                    onDismiss: { openIncidentSelect = false }
                )
            }
            .disabled(hasNoIncidents)

            Spacer()

            if showCountProgress {
                HStack(spacing: appTheme.gridItemSpacing) {
                    let mapCount = viewModel.casesCountMapText
                    if mapCount.isNotBlank {
                        Text(mapCount)
                            .foregroundColor(Color.white)
                    }
                    if viewModel.isLoadingData {
                        ProgressView()
                            .circularProgress()
                            .tint(.white)
                    }
                }
                .onTapGesture {
                    viewModel.syncWorksitesData()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .cardContainer(background: appTheme.colors.navigationContainerColor)
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    router.openSearchCases()
                } label: {
                    Image("ic_search", bundle: .module)
                        .mapOverlayButton()
                }

                Divider()
                    .frame(height: appTheme.buttonSize)

                Button {
                    router.openFilterCases()
                } label: {
                    Image("ic_dials", bundle: .module)
                        .mapOverlayButton()
                }
            }
            .cornerRadius(appTheme.cornerRadius)
            .shadow(radius: appTheme.shadowRadius)
            .if (viewModel.filtersCount > 0) {
                $0.overlay(alignment: .topTrailing) {
                    filterBadge(viewModel.filtersCount)
                }
            }
        }
        .onChange(of: viewModel.hasCasesCountProgress) { b in
            withAnimation(.easeIn(duration: appTheme.visibleSlowAnimationDuration)) {
                showCountProgress = b
            }
        }
    }
}

private struct CasesOverlayElements: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var appAlertState: AppAlertViewState
    @EnvironmentObject var viewModel: CasesViewModel

    let openAuthScreen: () -> Void

    @Binding var map: MKMapView

    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    let hasNoIncidents: Bool

    let animateToSelectedIncidentBounds: (_ bounds: LatLngBounds) -> Void

    var isShortScreen = false

    var body: some View {
        let isMapView = !viewModel.isTableView
        let isCompactLayout = appAlertState.showAlert && isShortScreen

        VStack {
            if isMapView {
                MapViewTopActions(
                    incidentSelectViewBuilder: incidentSelectViewBuilder,
                    hasNoIncidents: hasNoIncidents
                )
                .padding(.bottom)
            }

            HStack(spacing: 0) {
                if isMapView {
                    // TODO: Common dimensions
                    VStack(alignment: .leading, spacing: 16) {
                        MapControls(
                            map: map,
                            animateToSelectedIncidentBounds: animateToSelectedIncidentBounds,
                            isCompactLayout: isCompactLayout
                        )

                        if !isCompactLayout {
                            Spacer()
                        }
                    }
                }

                Spacer()

                // TODO: Common dimensions
                VStack(spacing: 16) {
                    if !isCompactLayout {
                        Spacer()
                    }

                    Button {
                        if viewModel.useMyLocation() {
                            map.userTrackingMode = .follow
                        }
                    } label: {
                        Image(systemName: "location")
                            .padding()
                    }
                    .styleRoundedRectanglePrimary()

                    Button {
                        router.createEditCase(
                            incidentId: viewModel.incidentsData.selectedId,
                            worksiteId: nil
                        )
                    } label: {
                        Image(systemName: "plus")
                            .padding()
                    }
                    .styleRoundedRectanglePrimary()

                    Button {
                        viewModel.toggleTableView()
                    } label: {
                        Image(isMapView ? "ic_table" : "ic_map", bundle: .module)
                    }
                    .styleRoundedRectanglePrimary()
                }
            }

            if appAlertState.showAlert,
               let appAlert = appAlertState.alertType {
                AppAlertView(
                    appAlert,
                    openAuthScreen
                )
                .padding(.top)
}
        }
        .padding()
    }
}

private struct MapResponsiveControls: View {
    @EnvironmentObject var viewModel: CasesViewModel

    let map: MKMapView

    let animateToSelectedIncidentBounds: (LatLngBounds) -> Void

    var body: some View {
        Button {
            map.setCamera(
                MKMapCamera(
                    lookingAtCenter: map.centerCoordinate,
                    fromDistance: CLLocationDistance(viewModel.mapMarkerZoomLevelHeight),
                    pitch: 0.0,
                    heading: 0.0
                ),
                animated: true
            )
        } label: {
            Image("ic_zoom_incident", bundle: .module)
                .mapOverlayButton()
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
        }

        Button {
            let bounds = viewModel.incidentLocationBounds.bounds
            animateToSelectedIncidentBounds(bounds)
        } label: {
            Image("ic_zoom_interactive", bundle: .module)
                .mapOverlayButton()
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
        }

//        Button {
//        } label: {
//            Image("ic_layers", bundle: .module)
//                .mapOverlayButton()
//                .cornerRadius(appTheme.cornerRadius)
//                .shadow(radius: appTheme.shadowRadius)
//        }
    }
}

private struct MapControls: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesViewModel

    let map: MKMapView
    let animateToSelectedIncidentBounds: (LatLngBounds) -> Void
    var isCompactLayout = false

    func zoomDelta(scale: Double) {
        var region = map.region
        let latDelta = region.span.latitudeDelta * scale
        let longDelta = region.span.longitudeDelta * scale
        region.span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        map.setRegion(region, animated: true)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                zoomDelta(scale: 0.5)
            } label: {
                Image(systemName: "plus")
                    .mapOverlayButton()
            }

            Divider()
                .frame(width: appTheme.buttonSize)

            Button {
                zoomDelta(scale: 2.0)
            } label: {
                Image(systemName: "minus")
                    .mapOverlayButton()
            }
        }
        .cornerRadius(appTheme.cornerRadius)
        .shadow(radius: appTheme.shadowRadius)

        if isCompactLayout {
            // TODO: Common dimensions
            HStack(spacing: 16) {
                MapResponsiveControls(
                    map: map,
                    animateToSelectedIncidentBounds: animateToSelectedIncidentBounds
                )
            }
        } else {
            MapResponsiveControls(
                map: map,
                animateToSelectedIncidentBounds: animateToSelectedIncidentBounds
            )
        }

    }
}

private struct MapOverlayButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .frame(width: appTheme.buttonSize, height: appTheme.buttonSize)
            .background(Color.white)
            .foregroundColor(Color.black)
    }
}

extension View {
    fileprivate func mapOverlayButton() -> some View {
        ModifiedContent(content: self, modifier: MapOverlayButtonModifier())
    }
}
