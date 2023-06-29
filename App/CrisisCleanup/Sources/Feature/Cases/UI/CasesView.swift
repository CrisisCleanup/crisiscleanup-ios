import SwiftUI
import SVGView
import MapKit

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder

    @State var showIncidentSelect = false
    @State var map = MKMapView()
    @State var totAnnots = 0
    @State var inViewAnnots = 0
    @State var prevIncident: Int64? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 40.83834587046632,
            longitude: 14.254053016537693),
        span: MKCoordinateSpan(
            latitudeDelta: 0.03,
            longitudeDelta: 0.03)
    )

    var body: some View {
        ZStack {

            MapView(map: $map, totAnnots: $totAnnots, inViewAnnots: $inViewAnnots, prevIncident: $prevIncident, viewModel: viewModel)

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
                            showIncidentSelect.toggle()
                        } label: {
                            IncidentDisasterImage(viewModel.incidentsData.selected)
                        }
                        .sheet(isPresented: $showIncidentSelect) {
                            incidentSelectViewBuilder.incidentSelectView( onDismiss: {showIncidentSelect = false} )
                        }.disabled(viewModel.incidentsData.incidents.isEmpty)

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
                                let center = viewModel.incidentLocationBounds.bounds.center
                                let latDelta = viewModel.incidentLocationBounds.bounds.northEast.latitude - viewModel.incidentLocationBounds.bounds.southWest.latitude
                                let longDelta = viewModel.incidentLocationBounds.bounds.northEast.longitude - viewModel.incidentLocationBounds.bounds.southWest.longitude
                                var region = map.region

                                let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
                                region = map.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude), span: span))
                                //                                map.region
                                map.setRegion(region, animated: true)

                            }

                        Image("ic_layers", bundle: .module)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(.top)

                        Spacer()

                    }
                    VStack {
                        HStack {
                            Spacer()

                            Text("~~\(inViewAnnots) cases out of \(totAnnots)")
                                .padding()
                                .background(Color.black)
                                .foregroundColor(Color.white)
                                .cornerRadius(5)

                            //                            Text("~~\(viewModel.incidentsData.selectedId.description) : \(viewModel.worksiteMapMarkers.count)")
                            //                                .padding()
                            //                                .background(Color.black)
                            //                                .foregroundColor(Color.white)
                            //                                .cornerRadius(5)
                            //

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
