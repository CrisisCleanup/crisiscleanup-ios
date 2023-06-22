import SwiftUI
import SVGView

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let incidentsTypeIconsAssetsFolder = "incident_type_icons/"

    @State var showIncidentSelect = false

    var body: some View{
        VStack {
            HStack {
                Button {
                    showIncidentSelect.toggle()
                } label: {
                    HStack{
                        Image(incidentsTypeIconsAssetsFolder+viewModel.incidentsData.selected.disasterLiteral, bundle: .module).foregroundColor(Color.blue)
                    }
                    let selectedIncident = viewModel.incidentsData.selected.shortName
                    let title = selectedIncident.isEmpty
                    ? t.translate(
                        TopLevelDestination.menu.titleTranslateKey,
                        TopLevelDestination.menu.titleLocalizationKey
                    )
                    : selectedIncident
                    Text(title)
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
            Spacer()
        }
        .padding()
    }
}
