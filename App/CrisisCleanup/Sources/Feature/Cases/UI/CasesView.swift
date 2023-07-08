import Foundation
import MapKit
import SVGView
import SwiftUI

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    @State var map = MKMapView()

    @State var openIncidentSelect = false

    let buttonSize = 48.0
    let buttonSizeDoublePlus1 = 97.0

    func animateToSelectedIncidentBounds(_ bounds: LatLngBounds) {
        let latDelta = bounds.northEast.latitude - bounds.southWest.latitude
        let longDelta = bounds.northEast.longitude - bounds.southWest.longitude
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)

        let center = bounds.center
        let regionCenter = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude), span: span)
        let region = map.regionThatFits(regionCenter)
        map.setRegion(region, animated: true)
    }

    func casesCountText(_ visibleCount: Int, _ totalCount: Int) -> String {
        {
            if visibleCount == totalCount || visibleCount == 0 {
                if visibleCount == 0 {
                    return t("info.t_of_t_cases").replacingOccurrences(of: "{visible_count}", with: "\(totalCount)")
                } else if totalCount == 1 {
                    return t("info.1_of_1_case")
                } else {
                    return t("info.t_of_t_cases").replacingOccurrences(of: "{visible_count}", with: "\(totalCount)")
                }
            } else {
                return t("info.v_of_t_cases")
                    .replacingOccurrences(of: "{visible_count}", with: "\(visibleCount)")
                    .replacingOccurrences(of: "{total_count}", with: "\(totalCount)")
            }
        }()
    }

    var body: some View {
        ZStack {

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
                .onReceive(viewModel.$incidentMapMarkers) { incidentAnnotations in
                    let annotations = map.annotations
                    if incidentAnnotations.annotationIdSet.isEmpty || annotations.count > 1500 {
                        map.removeAnnotations(annotations)
                    }
                    map.addAnnotations(incidentAnnotations.newAnnotations)
                    if map.annotations.isEmpty && !incidentAnnotations.annotationIdSet.isEmpty {
                        viewModel.onMissingMapMarkers()
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

            let hasNoIncidents = viewModel.incidentsData.incidents.isEmpty

            VStack {
                HStack {
                    VStack(spacing: 0) {
                        Button {
                            openIncidentSelect.toggle()
                        } label: {
                            IncidentDisasterImage(
                                viewModel.incidentsData.selected,
                                disabled: hasNoIncidents
                            )
                                .shadow(radius: 2)
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
                            buttonSize: buttonSize,
                            buttonSizeDoublePlus1: buttonSizeDoublePlus1
                        )

                        Spacer()

                    }
                    VStack {
                        HStack {
                            Spacer()

                            let (casesCount, totalCount) = viewModel.casesCount
                            if totalCount >= 0 {
                                Text(casesCountText(casesCount, totalCount))
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(appTheme.colors.navigationContainerColor)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(appTheme.cornerRadius)
                                    .shadow(radius: 2)
                            }

                            Spacer()

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
                                    // TODO: Use component
                                    Image("ic_dials", bundle: .module)
                                        .frame(width: buttonSize, height: buttonSize)
                                        .background(Color.white)
                                        .foregroundColor(Color.black)

                                }

                            }
                            .frame(width: buttonSizeDoublePlus1, height: buttonSize)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(appTheme.cornerRadius)
                            .shadow(radius: 2)

                        }
                        Spacer()
                    }
                }

                Spacer()

                HStack {
                    Spacer()
                    VStack {

                        Button {

                        } label: {
                            Image(systemName: "plus")
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(Color.black)
                                .frame(width: buttonSize, height: buttonSize)
                                .cornerRadius(appTheme.cornerRadius)
                                .shadow(radius: 2)
                        }

                        Button {

                        } label: {
                            Image("ic_table", bundle: .module)
                                .background(Color.yellow)
                                .foregroundColor(Color.black)
                                .frame(width: buttonSize, height: buttonSize)
                                .cornerRadius(appTheme.cornerRadius)
                                .shadow(radius: 2)
                                .padding(.bottom)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.onViewAppear()
            map.selectedAnnotations = []
        }
        .onDisappear { viewModel.onViewDisappear() }
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
        .shadow(radius: 2)
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
                .shadow(radius: 2)
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
                .shadow(radius: 2)
                .padding(.top)
        }

        Button {

        } label: {
            Image("ic_layers", bundle: .module)
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(appTheme.cornerRadius)
                .shadow(radius: 2)
                .padding(.top)
        }

    }
}
