import CachedAsyncImage
import SVGView
import SwiftUI

struct MenuView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: MenuViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    var body: some View {
        let hasNoIncidents = viewModel.incidentsData.incidents.isEmpty

        VStack {
            TopBar(
                viewModel: viewModel,
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen,
                hasNoIncidents: hasNoIncidents
            )
            .tint(.black)
            .padding([.horizontal, .top])

            Text(viewModel.versionText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.isProduction {
                MenuScreenNonProductionView(viewModel: viewModel)
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

    @ObservedObject var viewModel: MenuViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void
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
                openAuthScreen()
            } label: {
                if let url = viewModel.profilePicture?.url {
                    if viewModel.profilePicture?.isSvg == true {
                        SVGView(contentsOf: url)
                            .frame(width: 48, height: 48)
                            .padding([.vertical], 8)
                    } else {
                        CachedAsyncImage(url: url) { image in
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

private struct MenuScreenNonProductionView: View {
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        VStack {
            Button {
                router.openSyncInsights()
            } label: {
                Text("See sync logs")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isDebuggable {
                Text(viewModel.databaseVersionText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Button("Clear refresh token") {
                        viewModel.clearRefreshToken()
                    }
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
    }
}
