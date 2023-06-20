import SwiftUI
import SVGView

struct MenuView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: MenuViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    @State var showIncidentSelect = false

    var body: some View{
        VStack {
            HStack {
                Button {
                    showIncidentSelect.toggle()
                } label: {
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
                NavigationLink {
                    authenticateViewBuilder.authenticateView
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                } label: {
                    if let url = viewModel.profilePicture?.url {
                        if viewModel.profilePicture?.isSvg == true {
                            SVGView(contentsOf: url)
                                .frame(width: 30, height: 30)
                                .padding([.vertical], 8)
                        } else {
                            AsyncImage(url: url)
                                .frame(width: 30, height: 30)
                                .padding([.vertical], 8)
                        }
                    } else {
                        Text("Auth")
                    }
                }
            }
            .padding([.vertical])

            Text("\(viewModel.versionText)")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isDebuggable {
                Button("Expire token") {
                    viewModel.expireToken()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
        .padding()
    }
}
