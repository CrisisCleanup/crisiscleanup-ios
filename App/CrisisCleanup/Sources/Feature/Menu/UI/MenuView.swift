import SwiftUI

struct MenuView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var appAlertState: AppAlertViewState
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: MenuViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    var body: some View {
        let hasNoIncidents = viewModel.incidentsData.incidents.isEmpty

        VStack(alignment: .leading, spacing: 0) {
            TopBar(
                viewModel: viewModel,
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen,
                hasNoIncidents: hasNoIncidents
            )
            .tint(.black)
            .padding()

            ScrollView {
                VStack {
                    Text(viewModel.versionText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        router.openInviteTeammate()
                    } label: {
                        Text(t.t("usersVue.invite_new_user"))
                            .padding(.horizontal)
                    }
                    .stylePrimary()
                    .padding([.horizontal, .bottom])

                    Button {
                        router.openRequesetRedeploy()
                    } label: {
                        Text(t.t("requestRedeploy.request_redeploy"))
                            .padding(.horizontal)
                    }
                    .styleOutline()
                    .padding([.horizontal, .bottom])

                    Button {
                        router.openUserFeedback()
                    } label: {
                        Text(t.t("info.give_app_feedback"))
                            .padding(.horizontal)
                    }
                    .styleOutline()
                    .padding(.horizontal)

                    if !viewModel.isProduction {
                        MenuScreenNonProductionView(viewModel: viewModel)
                    }
                }
            }

            Spacer()

            // TODO: Common dimensions
            HStack(alignment: .center, spacing: 16) {
                Link(
                    t.t("publicNav.terms"),
                    destination: viewModel.termsOfServiceUrl
                )
                Link(
                    t.t("nav.privacy"),
                    destination: viewModel.privacyPolicyUrl
                )
            }
            .padding(.vertical, appTheme.listItemVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .center)

            if appAlertState.showAlert,
               let appAlert = appAlertState.alertType {
                AppAlertView(
                    appAlert,
                    openAuthScreen
                )
                .padding()
            }
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
                let title = selectedIncident.isEmptyIncident
                ? t.t(TopLevelDestination.menu.titleTranslateKey)
                : selectedIncident.shortName
                IncidentHeader(
                    incident: selectedIncident,
                    drop: !selectedIncident.isEmptyIncident,
                    text: title,
                    disabled: hasNoIncidents,
                    isLoading: viewModel.showHeaderLoading,
                    isSpaceConstrained: true
                )
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
                    AvatarView(
                        url: url,
                        isSvg: viewModel.profilePicture?.isSvg == true
                    )
                } else {
                    let imageSize = appTheme.avatarSize
                    Image(systemName: "person.circle")
                    .resizable()
                         .scaledToFill()
                         .frame(width: imageSize, height: imageSize)
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
