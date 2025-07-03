import SwiftUI

struct MenuView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var appAlertState: AppAlertViewState
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: MenuViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

    @State private var shareLocationWithOrg = false
    @State private var showExplainLocationPermission = false

    @State private var notifyDataSyncProgress = false
    @State private var showExplainNotificationPermission = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TopBar(
                incidentSelectViewBuilder: incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen,
            )
            .tint(.black)
            .padding()

            let showGettingStartedVideo = viewModel.menuItemVisibility.showGettingStartedVideo
            ScrollCenterContent {
                HotlineIncidentsView(
                    incidents: viewModel.hotlineIncidents
                )

                GettingStartedView(
                    showContent: showGettingStartedVideo,
                    hideGettingStartedVideo: { viewModel.showGettingStartedVideo(false) },
                    gettingStartedUrl: viewModel.gettingStartedVideoUrl,
                    isNonProduction: !viewModel.isProduction,
                    toggleGettingStartedSection: { viewModel.showGettingStartedVideo(true) }
                )

                IncidentCacheView(
                    incidentCachePreferences: viewModel.incidentCachePreferences,
                    hasSpeedNotAdaptive: viewModel.incidentDataCacheMetrics.hasSpeedNotAdaptive
                )

                Button(t.t("list.lists")) {
                    router.openLists()
                }
                .styleOutline()
                .padding()

                Button(t.t("usersVue.invite_new_user")) {
                    router.openInviteTeammate()
                }
                .stylePrimary()
                .padding([.horizontal, .bottom])

                Button(t.t("requestRedeploy.request_redeploy")) {
                    router.openRequesetRedeploy()
                }
                .styleOutline()
                .padding([.horizontal, .bottom])

                Button(t.t("info.give_app_feedback")) {
                    router.openUserFeedback()
                }
                .styleOutline()
                .padding([.horizontal, .bottom])

                Toggle(
                    t.t("appMenu.enable_notifications"),
                    isOn: $notifyDataSyncProgress
                )
                .padding([.horizontal, .bottom])
                .onReceive(viewModel.$notifyDataSyncProgress) { notify in
                    if notify != notifyDataSyncProgress {
                        notifyDataSyncProgress = notify
                    }
                }
                .onChange(of: notifyDataSyncProgress) { notify in
                    viewModel.notifyDataSyncProgress(notify)
                }
                .onReceive(viewModel.$hasNotificationAccess) { hasAccess in
                    notifyDataSyncProgress = hasAccess && viewModel.notifyDataSyncProgress
                }

                Toggle(
                    t.t("appMenu.share_location_organization"),
                    isOn: $shareLocationWithOrg
                )
                .padding(.horizontal)
                .onChange(of: viewModel.shareLocationWithOrg) { share in
                    if shareLocationWithOrg != share {
                        shareLocationWithOrg = share
                    }
                }
                .onChange(of: shareLocationWithOrg) { share in
                    if !share || viewModel.useMyLocation() {
                        viewModel.shareLocationWithOrg(share)
                    }
                }
                .onChange(of: viewModel.hasLocationAccess) { hasAccess in
                    if hasAccess && shareLocationWithOrg {
                        viewModel.shareLocationWithOrg(true)
                    }
                }

                Text(viewModel.versionText)
                    .foregroundStyle(appTheme.colors.neutralFontColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack(alignment: .center, spacing: appTheme.gridActionSpacing) {
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.onActivePhase()
            }
        }
        .onChange(of: viewModel.showExplainLocationPermission) { show in
            showExplainLocationPermission = show
        }
        .sheet(
            isPresented: $showExplainLocationPermission,
            onDismiss: {
                viewModel.showExplainLocationPermission = false
                shareLocationWithOrg = viewModel.hasLocationAccess && viewModel.shareLocationWithOrg
            }
        ) {
            RequestLocationView {
                viewModel.showExplainLocationPermission = false
            }
            .presentationDetents([.fraction(0.33), .medium])
        }
        .onChange(of: viewModel.showExplainNotificationPermission) { show in
            showExplainNotificationPermission = show
        }
        .sheet(
            isPresented: $showExplainNotificationPermission,
            onDismiss: {
                viewModel.showExplainNotificationPermission = false
                notifyDataSyncProgress = viewModel.hasNotificationAccess && viewModel.notifyDataSyncProgress
            }
        ) {
            RequestNotificationView {
                viewModel.showExplainNotificationPermission = false
            }
            .presentationDetents([.fraction(0.33), .medium])
        }
        .environmentObject(viewModel)
    }
}

private struct TopBar: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: MenuViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let openAuthScreen: () -> Void

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
                    isLoading: viewModel.isLoadingIncidentData,
                    isSpaceConstrained: true
                )
            }
            .disabled(viewModel.incidentsData.isFirstLoad)
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

private struct OpenSettingsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let bodyKey: String
    var actionKey: String = "info.app_settings"
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading) {
            Text(t.t(bodyKey))
            HStack {
                Spacer()
                Button(t.t(actionKey)) {
                    openSystemAppSettings()
                    onDismiss()
                }
                .padding()
            }
        }
        .padding()
    }
}

private struct RequestLocationView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var onDismiss: () -> Void = {}

    var body: some View {
        OpenSettingsView(
            bodyKey: "appMenu.share_location_organization_description",
            onDismiss: onDismiss
        )
    }
}

private struct RequestNotificationView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var onDismiss: () -> Void = {}

    var body: some View {
        OpenSettingsView(
            bodyKey: "appMenu.notification_access_request",
            onDismiss: onDismiss
        )
    }
}

private struct IncidentCacheView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    let incidentCachePreferences: IncidentWorksitesCachePreferences
    let hasSpeedNotAdaptive: Bool


    var body: some View {
        VStack(alignment: .leading) {
            if hasSpeedNotAdaptive {
                Text(t.t("appMenu.good_internet_use_adaptive"))
                    .padding(.bottom, appTheme.listItemVerticalPadding)
            }

            HStack(alignment: .center, spacing: appTheme.gridItemSpacing) {
                let syncingPolicy = if incidentCachePreferences.isPaused {
                    t.t("appMenu.pause_downloading_cases")
                } else if incidentCachePreferences.isBoundedNearMe {
                    t.t("appMenu.download_cases_near_me")
                } else if incidentCachePreferences.isBoundedByCoordinates {
                    t.t("appMenu.download_cases_specific_area")
                } else {
                    t.t("appMenu.adaptively_download_cases")
                }

                Text(syncingPolicy)

                Spacer()

                Button {
                    router.openIncidentDataCaching()
                } label: {
                    Text(t.t("actions.change"))
                }
                .foregroundStyle(appTheme.colors.actionLinkColor)
                .padding()
            }
        }
        .padding(.horizontal)
    }
}
