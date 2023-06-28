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

    var body: some View {
        ZStack {

            MapView(map: $map, viewModel: viewModel)

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
                            
                        
                        Image(systemName: "minus")
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                        
                        Image("ic_zoom_incident", bundle: .module)
//                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(.top)
                        
                        Image("ic_zoom_interactive", bundle: .module)
//                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(.top)
                        
                        Image("ic_layers", bundle: .module)
//                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(.top)
                        
                        Spacer()
                        
                    }
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text("~~5 cases out of 10")
                                .padding()
                                .background(Color.black)
                                .foregroundColor(Color.white)
                                .cornerRadius(5)
                            
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
