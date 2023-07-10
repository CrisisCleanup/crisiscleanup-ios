import SwiftUI
import SVGView

struct MenuView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: MenuViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    var body: some View {
        let hasNoIncidents = viewModel.incidentsData.incidents.isEmpty

        VStack {
            TopBar(
                viewModel: viewModel,
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                hasNoIncidents: hasNoIncidents
            )
            .tint(.black)
            .padding([.horizontal, .top])

            Text(viewModel.versionText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isDebuggable {
                MenuScreenDebugView(viewModel: viewModel)
            }

            Spacer()
        }
        .background(.white)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct TopBar: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: MenuViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let hasNoIncidents: Bool

    @State var showIncidentSelect = false

    var body: some View {

        HStack {
            Button {
                showIncidentSelect.toggle()
            } label: {
                let selectedIncident = viewModel.incidentsData.selected

                IncidentDisasterImage(
                    selectedIncident,
                    disabled: hasNoIncidents
                )

                let title = selectedIncident.isEmptyIncident
                ? t.t(TopLevelDestination.menu.titleTranslateKey)
                : selectedIncident.shortName
                Text(title)
                    .font(.title2)
                    .padding(.leading, 8)

                if !selectedIncident.isEmptyIncident {
                    DropDownIcon()
                }
            }
            .sheet(
                isPresented: $showIncidentSelect,
                onDismiss: {
                    incidentSelectViewBuilder.onIncidentSelectDismiss()
                }
            ) {
                incidentSelectViewBuilder.incidentSelectView(
                    onDismiss: { showIncidentSelect = false }
                )
            }
            .disabled(hasNoIncidents)

            Spacer()
            Button {
                router.openAuthentication()
            } label: {
                if let url = viewModel.profilePicture?.url {
                    if viewModel.profilePicture?.isSvg == true {
                        SVGView(contentsOf: url)
                            .frame(width: 48, height: 48)
                            .padding([.vertical], 8)
                    } else {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
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
