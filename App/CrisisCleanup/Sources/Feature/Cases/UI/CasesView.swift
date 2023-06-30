import SwiftUI
import SVGView
import MapKit

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder

    @State var openIncidentSelect = false
    @State var map = MKMapView()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 40.83834587046632,
            longitude: 14.254053016537693),
        span: MKCoordinateSpan(
            latitudeDelta: 0.03,
            longitudeDelta: 0.03)
    )

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
                .onReceive(viewModel.$incidentsData) { data in
                    let annotations = map.annotations
                    if annotations.isNotEmpty,
                       (annotations[0] as! WorksiteAnnotationMapMark).source.incidentId != data.selectedId {
                        map.removeAnnotations(annotations)
                    }
                }
                .onReceive(viewModel.$worksiteMapMarkers) { addAnnotations in
                    let annotations = map.annotations
                    if annotations.count > 5000 {
                        map.removeAnnotations(annotations)
                    }
                    map.addAnnotations(addAnnotations)
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
                                    .cornerRadius(5)
                            }

                            Spacer()

                            NavigationLink {
                                casesSearchViewBuilder.casesSearchView
                                    .navigationBarTitle("search-title")
                            } label: {
                                Image("ic_search", bundle: .module)
                                    .background(Color.white)
                                    .foregroundColor(Color.black)
                                    .cornerRadius(5)
                            }

                            Image("ic_dials", bundle: .module)
                                .background(Color.white)
                                .foregroundColor(Color.black)
                                .cornerRadius(5)

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
                            .cornerRadius(5)

                        Image("ic_table", bundle: .module)
                        //                            .padding()
                            .background(Color.yellow)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(.top)
                    }
                }
            }
            .padding()
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
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
            .cornerRadius(5)
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
            .cornerRadius(5)
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
            .cornerRadius(5)
            .padding(.top)
            .onTapGesture {
                //                                map.camera.centerCoordinateDistance =
                map.setCamera(MKMapCamera(lookingAtCenter: map.centerCoordinate, fromDistance: CLLocationDistance(50*1000), pitch: 0.0, heading: 0.0), animated: true)
            }

        Image("ic_zoom_interactive", bundle: .module)
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(5)
            .padding(.top)
            .onTapGesture {
                let bounds = viewModel.incidentLocationBounds.bounds
                animateToSelectedIncidentBounds(bounds)
            }

        Image("ic_layers", bundle: .module)
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(5)
            .padding(.top)
    }
}
