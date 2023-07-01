import SwiftUI
import SVGView
import MapKit

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder
    let casesFilterViewBuilder: CasesFilterViewBuilder
    let viewCaseViewBuilder: ViewCaseViewBuilder

    @State var map = MKMapView()

    @State var openFilters = false
    @State var openIncidentSelect = false

    @State var viewWorksite = false
    @State var openWorksiteIds: (Int64, Int64) = (0, 0)

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
        ZStack {

            MapView(map: $map, viewModel: viewModel)
                .onReceive(viewModel.$incidentLocationBounds) { bounds in
                    animateToSelectedIncidentBounds(bounds.bounds)
                }
                .onReceive(viewModel.$incidentMapMarkers) { incidentAnnotations in
                    let annotations = map.annotations
                    if incidentAnnotations.annotationIdSet.isEmpty || annotations.count > 1500 {
                        map.removeAnnotations(annotations)
                    }
                    map.addAnnotations(incidentAnnotations.newAnnotations)
                }
                .onReceive(viewModel.$selectedCaseAnnotation) { marker in
                    let worksiteId = marker.source?.id ?? 0
                    openWorksiteIds = (viewModel.incidentsData.selectedId, worksiteId)
                    viewWorksite = worksiteId > 0
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

            VStack {
                HStack {
                    VStack(spacing: 0) {
                        Button {
                            openIncidentSelect.toggle()
                        } label: {
                            IncidentDisasterImage(viewModel.incidentsData.selected)
                        }
                        .sheet(isPresented: $openIncidentSelect) {
                            incidentSelectViewBuilder.incidentSelectView( onDismiss: {openIncidentSelect = false} )
                        }.disabled(viewModel.incidentsData.incidents.isEmpty)

                        MapControls(
                            viewModel: viewModel,
                            map: map,
                            animateToSelectedIncidentBounds: animateToSelectedIncidentBounds
                        )

                        Spacer()

                    }
                    VStack {
                        HStack {
                            Spacer()

                            let (casesCount, totalCount) = viewModel.casesCount
                            if totalCount >= 0 {
                                Text("~~\(casesCount) cases\nof \(totalCount)")
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(appTheme.colors.navigationContainerColor)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(appTheme.cornerRadius)
                            }

                            Spacer()

                            NavigationLink {
                                casesSearchViewBuilder.casesSearchView
                                 .navigationBarHidden(true)
                            } label: {
                                Image("ic_search", bundle: .module)
                                    .background(Color.white)
                                    .foregroundColor(Color.black)
                                    .cornerRadius(appTheme.cornerRadius)
                            }

                            Button {
                                openFilters = true
                            } label: {
                                // TODO: Use component
                                Image("ic_dials", bundle: .module)
                                    .background(Color.white)
                                    .foregroundColor(Color.black)
                                    .cornerRadius(appTheme.cornerRadius)
                            }

                        }
                        Spacer()
                    }
                }

                Spacer()

                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "plus")
                            .padding()
                            .background(Color.yellow)
                            .foregroundColor(Color.black)
                            .cornerRadius(appTheme.cornerRadius)

                        Image("ic_table", bundle: .module)
                            .background(Color.yellow)
                            .foregroundColor(Color.black)
                            .cornerRadius(appTheme.cornerRadius)
                            .padding(.top)
                    }
                }
            }
            .padding()
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .navigationDestination(isPresented: $viewWorksite) {
            let (incidentId, worksiteId) = openWorksiteIds
            viewCaseViewBuilder.viewCaseView(
                incidentId: incidentId,
                worksiteId: worksiteId
            )
            .onDisappear() {
                // TODO: This likely does not work when another view is pushed onto the stack... Implement an observer of the current stack path
                print("View case disappear")
                viewCaseViewBuilder.onViewCasePopped(
                    incidentId: openWorksiteIds.0,
                    worksiteId: openWorksiteIds.1
                )
                openWorksiteIds = (0, 0)
                map.selectedAnnotations = []
            }
        }
        .navigationDestination(isPresented: $openFilters) {
            if openFilters {
                casesFilterViewBuilder.casesFilterView
                    .onDisappear {
                        openFilters = false
                    }
            }
        }
    }
}

private struct MapControls: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    var map: MKMapView
    var animateToSelectedIncidentBounds: (LatLngBounds) -> Void

    var body: some View {
        Image(systemName: "plus")
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(appTheme.cornerRadius)
            .padding(.vertical)
            .onTapGesture {
                print("zooming in")
                print(map.region.span.latitudeDelta)
                var region = map.region
                let latDelta = region.span.latitudeDelta*0.60
                let longDelta = region.span.longitudeDelta*0.60
                region.span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
                map.setRegion(region, animated: true)

            }

        Image(systemName: "minus")
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(appTheme.cornerRadius)
            .onTapGesture {
                print("zooming out")
                var region = map.region
                let latDelta = region.span.latitudeDelta*1.30
                let longDelta = region.span.longitudeDelta*1.30
                region.span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
                map.setRegion(region, animated: true)
            }

        Image("ic_zoom_incident", bundle: .module)
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(appTheme.cornerRadius)
            .padding(.top)
            .onTapGesture {
                //                                map.camera.centerCoordinateDistance =
                map.setCamera(MKMapCamera(lookingAtCenter: map.centerCoordinate, fromDistance: CLLocationDistance(50*1000), pitch: 0.0, heading: 0.0), animated: true)
            }

        Image("ic_zoom_interactive", bundle: .module)
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(appTheme.cornerRadius)
            .padding(.top)
            .onTapGesture {
                let bounds = viewModel.incidentLocationBounds.bounds
                animateToSelectedIncidentBounds(bounds)
            }

        Image("ic_layers", bundle: .module)
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(appTheme.cornerRadius)
            .padding(.top)
    }
}
