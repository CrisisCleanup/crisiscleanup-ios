import SwiftUI
import SVGView

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder

    let incidentsTypeIconsAssetsFolder = "incident_type_icons/"

    @State var showIncidentSelect = false

    var body: some View {
        VStack {
            HStack {
                Button {
                    showIncidentSelect.toggle()
                } label: {
                    let selectedIncident = viewModel.incidentsData.selected
                    let icon = selectedIncident.disasterLiteral.isEmpty
                    ? "other" : selectedIncident.disasterLiteral
                    Image(incidentsTypeIconsAssetsFolder+icon, bundle: .module).foregroundColor(Color.blue)

                    // TODO: Dropdown arrow. Use SF Symbols.
                }
                .sheet(isPresented: $showIncidentSelect) {
                    incidentSelectViewBuilder.incidentSelectView( onDismiss: {showIncidentSelect = false} )
                }.disabled(viewModel.incidentsData.incidents.isEmpty)
                Spacer()
            }
            .padding([.vertical])

            Spacer()
            Text("cases")
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(WorkTypeType.allCases) { workTypeType in
                        Text(workTypeType.rawValue)
                        if let imageName = workTypeIconLookup[workTypeType] {
                            Image(imageName, bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .padding([.vertical], 8)
                        }
                    }
                }
            }
            Spacer()
            NavigationLink {
                casesSearchViewBuilder.casesSearchView
                    .navigationBarTitle("search-title")
            } label: {
                Text("search-button")
            }
            Spacer()
        }
        .padding()
    }
}
