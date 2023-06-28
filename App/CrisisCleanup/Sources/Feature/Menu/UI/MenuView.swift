import SwiftUI
import SVGView

struct MenuView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: MenuViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    var body: some View {
        VStack {
            TopBar(
                viewModel: viewModel,
                authenticateViewBuilder: authenticateViewBuilder,
                incidentSelectViewBuilder: incidentSelectViewBuilder
            )

            Text(viewModel.versionText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isDebuggable {
                MenuScreenDebugView(viewModel: viewModel)
            }

            Spacer()
        }
        .padding()
        .background(.white)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct TopBar: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: MenuViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    @State var showIncidentSelect = false

    var body: some View {
        HStack {
            Button {
                showIncidentSelect.toggle()
            } label: {
                let selectedIncident = viewModel.incidentsData.selected

                IncidentDisasterImage(selectedIncident)

                let title = selectedIncident.isEmptyIncident
                ? t(TopLevelDestination.menu.titleTranslateKey)
                : selectedIncident.shortName
                Text(title)
                    .font(.title2)
                    .padding(.leading, 8)

                if !selectedIncident.isEmptyIncident {
                    Image(systemName: "arrowtriangle.down.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 8)
                }
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
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 36, height: 36)
                        .padding([.vertical], 8)
                    }
                } else {
                    Text("Auth")
                }
            }
        }
    }
}

private struct MenuScreenDebugView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        VStack {
            Text(viewModel.databaseVersionText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Expire token") {
                viewModel.expireToken()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
