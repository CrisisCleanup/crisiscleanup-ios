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

            let showGettingStartedVideo = viewModel.menuItemVisibility.showGettingStartedVideo
            ScrollCenterContent {
                GettingStartedView(
                    showContent: showGettingStartedVideo,
                    hideGettingStartedVideo: { viewModel.showGettingStartedVideo(false) },
                    gettingStartedUrl: viewModel.gettingStartedVideoUrl,
                    isNonProduction: !viewModel.isProduction,
                    toggleGettingStartedSection: { viewModel.showGettingStartedVideo(true) }
                )

                Button {
                    router.openLists()
                } label: {
                    Text(t.t("~~Lists"))
                        .padding(.horizontal)
                }
                .styleOutline()
                .padding()

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

                Text(viewModel.versionText)
                    .foregroundStyle(appTheme.colors.neutralFontColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

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

                if !viewModel.isProduction {
                    MenuScreenNonProductionView(viewModel: viewModel)
                }
            }

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
                IncidentHeaderView(
                    incident: selectedIncident,
                    showDropdown: !selectedIncident.isEmptyIncident,
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

private struct GettingStartedView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var showContent: Bool
    var hideGettingStartedVideo: () -> Void
    var gettingStartedUrl: URL
    var isNonProduction: Bool = false
    var toggleGettingStartedSection: () -> Void = {}

    var body: some View {
        if showContent {
            VStack {
                HStack {
                    Text(t.t("appMenu.training_video"))
                        .fontHeader2()
                    Spacer()
                    Button(t.t("actions.hide")) {
                        hideGettingStartedVideo()
                    }
                }
                .padding(.bottom, appTheme.listItemVerticalPadding)

                VStack(alignment: .leading) {
                    Image("getting_starting_video_thumbnail", bundle: .module)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 128)
                        .clipped()
                        .overlay {
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .padding(24)
                                .background(.white.opacity(0.5))
                                .clipShape(Circle())
                        }

                    Text(t.t("appMenu.quick_app_intro"))
                        .fontHeader3()
                        .padding(.horizontal)
                        .padding(.bottom, appTheme.listItemVerticalPadding)
                }
                .cardContainer()
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.open(gettingStartedUrl)
                }
            }
            .padding([.horizontal, .top])
        } else if isNonProduction {
            Button("show getting started section") {
                toggleGettingStartedSection()
            }
            .foregroundStyle(appTheme.colors.actionLinkColor)
            .padding()
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
