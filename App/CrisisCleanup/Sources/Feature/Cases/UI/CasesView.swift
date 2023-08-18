import Foundation
import MapKit
import SVGView
import SwiftUI

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    @State var map = MKMapView()

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
                MapView(
                    map: $map,
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

            if viewModel.isMapBusy {
                VStack {
                    ProgressView()
                        .frame(alignment: .center)
                }
            }

            CasesOverlayElements(
                openAuthScreen: openAuthScreen,
                map: $map,
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                hasNoIncidents: hasNoIncidents,
                animateToSelectedIncidentBounds: animateToSelectedIncidentBounds
            )

            if viewModel.showExplainLocationPermssion {
                OpenAppSettingsDialog(
                    title: t.t("info.allow_access_to_location"),
                    dismissDialog: { viewModel.showExplainLocationPermssion = false }
                ) {
                    Text(t.t("info.location_permission_explanation"))
                        .padding(.horizontal)
                }
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

private struct CasesOverlayElements: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var appAlertState: AppAlertViewState

    @EnvironmentObject var viewModel: CasesViewModel

    let openAuthScreen: () -> Void

    @Binding var map: MKMapView

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let hasNoIncidents: Bool
    let animateToSelectedIncidentBounds: (_ bounds: LatLngBounds) -> Void

    @State var openIncidentSelect = false

    @State var showCountProgress = false

    var body: some View {
        let isMapView = !viewModel.isTableView

        VStack {
            if isMapView {
                HStack {
                    VStack(spacing: 0) {
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

                        MapControls(
                            viewModel: viewModel,
                            map: map,
                            animateToSelectedIncidentBounds: animateToSelectedIncidentBounds,
                            buttonSize: appTheme.buttonSize,
                            buttonSizeDoublePlus1: appTheme.buttonSizeDoublePlus1
                        )

                        Spacer()

                    }
                    VStack {
                        HStack {
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

                            let buttonSize = appTheme.buttonSize

                            HStack(spacing: 0) {
                                Button {
                                    router.openSearchCases()
                                } label: {
                                    Image("ic_search", bundle: .module)
                                        .frame(width: buttonSize, height: buttonSize)
                                        .background(Color.white)
                                        .foregroundColor(Color.black)
                                }

                                Divider()
                                    .frame(height: buttonSize)

                                Button {
                                    router.openFilterCases()
                                } label: {
                                    Image("ic_dials", bundle: .module)
                                        .frame(width: buttonSize, height: buttonSize)
                                        .background(Color.white)
                                        .foregroundColor(Color.black)
                                }
                                .if(viewModel.filtersCount > 0) {
                                    // TODO: Don't clip overlay
                                    $0.overlay(alignment: .topTrailing) {
                                        filterBadge(viewModel.filtersCount)
                                    }
                                }
                            }
                            .frame(width: appTheme.buttonSizeDoublePlus1, height: buttonSize)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(appTheme.cornerRadius)
                            .shadow(radius: appTheme.shadowRadius)
                        }
                        Spacer()
                    }
                    .onChange(of: viewModel.hasCasesCountProgress) { b in
                        withAnimation(.easeIn(duration: appTheme.visibleSlowAnimationDuration)) {
                            showCountProgress = b
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()

                // TODO: Common dimensions
                VStack(spacing: 16) {
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
            }
        }
        .padding()
    }
}

private struct MapControls: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let map: MKMapView
    let animateToSelectedIncidentBounds: (LatLngBounds) -> Void

    let buttonSize: Double
    let buttonSizeDoublePlus1: Double

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
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Color.white)
                    .foregroundColor(Color.black)
            }

            Divider()

            Button {
                zoomDelta(scale: 1.5)
            } label: {
                Image(systemName: "minus")
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Color.white)
                    .foregroundColor(Color.black)
            }

        }
        .background(Color.white)
        .frame(width: buttonSize, height: buttonSizeDoublePlus1)
        .cornerRadius(appTheme.cornerRadius)
        .shadow(radius: appTheme.shadowRadius)
        .padding(.top)

        Button {
            map.setCamera(
                MKMapCamera(
                    lookingAtCenter: map.centerCoordinate,
                    // TODO: Calculate based on zoom level rather than distance
                    fromDistance: CLLocationDistance(500*1000),
                    pitch: 0.0,
                    heading: 0.0
                ),
                animated: true
            )
        } label: {
            Image("ic_zoom_incident", bundle: .module)
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
                .padding(.top)
        }

        Button {
            let bounds = viewModel.incidentLocationBounds.bounds
            animateToSelectedIncidentBounds(bounds)
        } label: {
            Image("ic_zoom_interactive", bundle: .module)
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: appTheme.shadowRadius)
                .padding(.top)
        }

//        Button {
//        } label: {
//            Image("ic_layers", bundle: .module)
//                .frame(width: buttonSize, height: buttonSize)
//                .background(Color.white)
//                .foregroundColor(Color.black)
//                .cornerRadius(appTheme.cornerRadius)
//                .shadow(radius: appTheme.shadowRadius)
//                .padding(.top)
//        }
    }
}
