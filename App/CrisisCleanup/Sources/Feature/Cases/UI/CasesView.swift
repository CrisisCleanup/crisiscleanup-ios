import SwiftUI
import SVGView
import MapKit

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder

    let incidentsTypeIconsAssetsFolder = "incident_type_icons/"

    @State var showIncidentSelect = false
    @State var map = MKMapView()

    var body: some View {
        ZStack {
            
            MapView(map: $map, viewModel: viewModel)
               
            VStack {
                HStack {
                    VStack(spacing: 0) {
                        Button {
                            showIncidentSelect.toggle()
                        
                            print("toggling")
                        } label: {
                            let selectedIncident = viewModel.incidentsData.selected
                            let icon = selectedIncident.disasterLiteral.isEmpty
                            ? "other" : selectedIncident.disasterLiteral
                            Image(incidentsTypeIconsAssetsFolder+icon, bundle: .module).foregroundColor(Color.blue)
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
    }
}
