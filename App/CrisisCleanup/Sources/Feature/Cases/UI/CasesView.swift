import Foundation
import MapKit
import SVGView
import SwiftUI

struct CasesView: View {
    @ObservedObject var viewModel: CasesViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    var body: some View {
        CasesLayoutView(
            incidentSelectViewBuilder: incidentSelectViewBuilder,
            openAuthScreen: openAuthScreen
        )
        .environmentObject(viewModel)
    }
}

struct CasesLayoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewLayout: ViewLayoutDescription
    @EnvironmentObject var viewModel: CasesViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    @State var map = MKMapView()
    @State private var isSatelliteMapType = false
    @State private var showMapBusyIndicator = false
    @State private var phoneCallNumbers = [ParsedPhoneNumber]()

    func animateToSelectedIncidentBounds(_ bounds: LatLngBounds) {
        let latDelta = bounds.northEast.latitude - bounds.southWest.latitude
        let longDelta = bounds.northEast.longitude - bounds.southWest.longitude
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)

        let center = bounds.center
        let center2d = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
        let regionCenter = MKCoordinateRegion(center: center2d, span: span)
        let region = map.regionThatFits(regionCenter)
        map.setRegion(region, animated: true)
    }

    var body: some View {
        let hasNoIncidents = viewModel.incidentsData.incidents.isEmpty

        ZStack {
            if viewModel.isTableView {
                CasesTableView(
                    phoneCallNumbers: $phoneCallNumbers,
                    incidentSelectViewBuilder: incidentSelectViewBuilder,
                    hasNoIncidents: hasNoIncidents
                )
            } else {
                CasesMapView(
                    map: $map,
                    focusWorksiteCenter: $viewModel.editedWorksiteLocation,
                    isSatelliteMapType: $isSatelliteMapType,
                    viewModel: viewModel,
                    mapOverlays: map.makeOverlayPolygons(),
                    onSelectWorksite: { worksiteId in
                        let incidentId = viewModel.incidentsData.selectedId
                        router.viewCase(incidentId: incidentId, worksiteId: worksiteId)
                    }
                )
                .onReceive(viewModel.$mapCameraBounds) { bounds in
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
                        // TODO: Does this center once or follow until disengaged?
                        map.userTrackingMode = .follow
                    }
                }
            }

            let dataProgress = viewModel.dataProgress
            if dataProgress.showProgress {
                let baseColor = appTheme.colors.primaryOrangeColor
                let progressColor = dataProgress.isSecondaryData ? baseColor.disabledAlpha() : baseColor
                VStack {
                    ProgressView(value: dataProgress.progress, total: 1)
                        .progressViewStyle(
                            LinearProgressViewStyle(tint: progressColor)
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
                isSatelliteMapType: $isSatelliteMapType,
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

            if phoneCallNumbers.isNotEmpty {
                PhoneCallDialog(phoneNumbers: phoneCallNumbers) {
                    phoneCallNumbers = []
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

    @State private var openIncidentSelect = false

    @State private var showCountProgress = false

    var body: some View {
        HStack {
            Button {
                openIncidentSelect.toggle()
            } label: {
                IncidentDisasterImage(
                    viewModel.incidentsData.selected,
                    background: .white
                )
                .shadow(radius: appTheme.shadowRadius)
            }
            .disabled(viewModel.incidentsData.isFirstLoad)
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
                .onLongPressGesture {
                    viewModel.syncWorksitesData(true)
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
        .onAppear {
            showCountProgress = viewModel.hasCasesCountProgress
        }
    }
}

private struct CasesOverlayElements: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var appAlertState: AppAlertViewState
    @EnvironmentObject var viewModel: CasesViewModel

    let openAuthScreen: () -> Void

    @Binding var map: MKMapView
    @Binding var isSatelliteMapType: Bool

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
                )
                .padding(.bottom)
            }

            HStack(spacing: 0) {
                if isMapView {
                    VStack(alignment: .leading, spacing: appTheme.gridActionSpacing) {
                        MapControls(
                            map: map,
                            animateToSelectedIncidentBounds: animateToSelectedIncidentBounds,
                            isSatelliteMapType: $isSatelliteMapType,
                            isCompactLayout: isCompactLayout
                        )

                        if !isCompactLayout {
                            Spacer()
                        }
                    }
                }

                Spacer()

                VStack(spacing: appTheme.gridActionSpacing) {
                    if !isCompactLayout {
                        Spacer()
                    }

                    if isMapView {
                        Button {
                            if viewModel.useMyLocation() {
                                map.userTrackingMode = .follow
                            }
                        } label: {
                            Image(systemName: "location")
                                .padding()
                        }
                        .styleRoundedRectanglePrimary()
                    }

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
                    .disabled(hasNoIncidents)

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
    @Binding var isSatelliteMapType: Bool

    @State private var showLayersView = false

    var body: some View {
        Button {
            // TODO: Calculate consistent distance rather than empirical magic number
            //       Print mapView.region.span to see inconsistency even when fromDistance is constant
            //       Panning the map shows a changing centerCoordinateDistance
            let mapMarkerZoomLevelHeight = 300_000
            viewModel.onZoomIncident()
            map.setCamera(
                MKMapCamera(
                    lookingAtCenter: map.centerCoordinate,
                    fromDistance: CLLocationDistance(mapMarkerZoomLevelHeight),
                    pitch: 0.0,
                    heading: 0.0,
                ),
                animated: true,
            )
        } label: {
            Image("ic_zoom_incident", bundle: .module)
                .mapOverlayButton()
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
        }

        Button {
            let bounds = viewModel.incidentMapBounds.bounds
            animateToSelectedIncidentBounds(bounds)
        } label: {
            Image("ic_zoom_interactive", bundle: .module)
                .mapOverlayButton()
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
        }

        Button {
            showLayersView = true
        } label: {
            Image("ic_layers", bundle: .module)
                .mapOverlayButton()
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
        }
        .sheet(
            isPresented: $showLayersView,
            onDismiss: {
                showLayersView = false
            }
        ) {
            MapLayersView(isSatelliteMapType: $isSatelliteMapType)
                .listItemModifier()
                .onChange(of: isSatelliteMapType) { newValue in
                    map.mapType = newValue ? .satellite : .standard
                    // TODO: Toggle overlay
                }
                .presentationDetents([.medium, .fraction(0.3)])
        }
    }
}

private struct MapControls: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesViewModel

    let map: MKMapView
    let animateToSelectedIncidentBounds: (LatLngBounds) -> Void
    @Binding var isSatelliteMapType: Bool

    var isCompactLayout = false

    func zoomDelta(scale: Double) {
        var region = map.region
        let latDelta = region.span.latitudeDelta * scale
        guard latDelta < 180 else {
            return
        }

        let longDelta = region.span.longitudeDelta * scale
        guard longDelta < 360 else {
            return
        }

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
            HStack(spacing: appTheme.gridActionSpacing) {
                MapResponsiveControls(
                    map: map,
                    animateToSelectedIncidentBounds: animateToSelectedIncidentBounds,
                    isSatelliteMapType: $isSatelliteMapType
                )
            }
        } else {
            MapResponsiveControls(
                map: map,
                animateToSelectedIncidentBounds: animateToSelectedIncidentBounds,
                isSatelliteMapType: $isSatelliteMapType
            )
        }

    }
}

private struct MapLayersView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var isSatelliteMapType: Bool

    var borderColor: Color = appTheme.colors.primaryBlueColor
    var borderWidth: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: appTheme.gridActionSpacing) {
            Text(t.t("worksiteMap.toggle_map_type"))
                .fontHeader3()

            let imageSize = appTheme.buttonSize
            HStack {
                VStack(spacing: appTheme.gridItemSpacing) {
                    Button {
                        isSatelliteMapType = false
                    } label: {
                        Image(systemName: "map")
                            .frame(width: imageSize, height: imageSize)
                            .if (!isSatelliteMapType) {
                                $0.roundedBorder(color: borderColor, lineWidth: borderWidth)
                            }
                    }
                    Text(t.t("worksiteMap.street_map"))
                }
                VStack(spacing: appTheme.gridItemSpacing) {
                    Button {
                        isSatelliteMapType = true
                    } label: {
                        Image(systemName: "mountain.2")
                            .frame(width: imageSize, height: imageSize)
                            .if (isSatelliteMapType) {
                                $0.roundedBorder(color: borderColor, lineWidth: borderWidth)
                            }
                    }
                    Text(t.t("worksiteMap.satellite_map"))
                }
            }
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
