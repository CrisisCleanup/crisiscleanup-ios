import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.translator) var translator

    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var router: NavigationRouter
    @ObservedObject var appAlerts: AppAlertViewState

    let locationManager: LocationManager

    let authenticateViewBuilder: AuthenticateViewBuilder
    let volunteerOrgViewBuilder: VolunteerOrgViewBuilder
    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder
    let casesFilterViewBuilder: CasesFilterViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder
    let viewCaseViewBuilder: ViewCaseViewBuilder
    let caseAddNoteViewBuilder: CaseAddNoteViewBuilder
    let createEditCaseViewBuilder: CreateEditCaseViewBuilder
    let caseShareViewBuilder: CaseShareViewBuilder
    let caseFlagsViewBuilder: CaseFlagsViewBuilder
    let caseHistoryViewBuilder: CaseHistoryViewBuilder
    let transferWorkTypeViewBuilder: TransferWorkTypeViewBuilder
    let viewImageViewBuilder: ViewImageViewBuilder
    let worksiteImagesViewBuilder: WorksiteImagesViewBuilder
    let caseSearchLocationViewBuilder: CaseSearchLocationViewBuilder
    let caseMoveOnMapViewBuilder: CaseMoveOnMapViewBuilder
    let userFeedbackViewBuilder: UserFeedbackViewBuilder
    let inviteTeammateViewBuilder: InviteTeammateViewBuilder
    let requestRedeployViewBuilder: RequestRedeployViewBuilder
    let listsViewBuilder: ListsViewBuilder
    let syncInsightsViewBuilder: SyncInsightsViewBuilder

    @State private var selectedTab = TopLevelDestination.cases

    @State private var deviceSize = ViewLayoutDescription()

    @State private var dividerHeight: CGFloat = 32.0
    @State private var dividerOffset: CGFloat = -6.0

    private func clearAuthNavigation() {
        if let lastPath = router.path.last {
            var popToRoot = false
            if lastPath == NavigationRoute.loginWithEmail {
                popToRoot = true
            } else if case NavigationRoute.phoneLoginCode = lastPath {
                popToRoot = true
            } else if case NavigationRoute.magicLinkLoginCode = lastPath {
                popToRoot = true
            }
            if popToRoot {
                router.clearAuthRoutes()
                viewModel.showAuthScreen = false
            }
        }
    }

    var body: some View {
        let isNavigatingAuth = viewModel.showAuthScreen ||
        !viewModel.viewData.showMainContent
        ZStack {
            Group {
                switch viewModel.viewData.state {
                case .loading:
                    Image("crisis_cleanup_logo", bundle: .module)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240)

                case .unsupportedBuild:
                    UnsupportedBuildView(supportedInfo: viewModel.minSupportedVersion)
                case .ready:
                    let hideAuthScreen = {
                        viewModel.showAuthScreen = false
                    }
                    if isNavigatingAuth {
                        AuthenticationNavigationStack(
                            authenticateViewBuilder: authenticateViewBuilder,
                            volunteerOrgViewBuilder: volunteerOrgViewBuilder,
                            exitAuthNavigation: hideAuthScreen
                        )
                    } else if !viewModel.viewData.hasAcceptedTerms {
                        TermsView(viewModel: viewModel)
                    } else {
                        MainNavigationStack(
                            viewModel: viewModel,
                            casesViewBuilder: casesViewBuilder,
                            menuViewBuilder: menuViewBuilder,
                            casesFilterViewBuilder: casesFilterViewBuilder,
                            casesSearchViewBuilder: casesSearchViewBuilder,
                            viewCaseViewBuilder: viewCaseViewBuilder,
                            caseAddNoteViewBuilder: caseAddNoteViewBuilder,
                            createEditCaseViewBuilder: createEditCaseViewBuilder,
                            caseShareViewBuilder: caseShareViewBuilder,
                            caseFlagsViewBuilder: caseFlagsViewBuilder,
                            caseHistoryViewBuilder: caseHistoryViewBuilder,
                            transferWorkTypeViewBuilder: transferWorkTypeViewBuilder,
                            viewImageViewBuilder: viewImageViewBuilder,
                            worksiteImagesViewBuilder: worksiteImagesViewBuilder,
                            caseSearchLocationViewBuilder: caseSearchLocationViewBuilder,
                            caseMoveOnMapViewBuilder: caseMoveOnMapViewBuilder,
                            userFeedbackViewBuilder: userFeedbackViewBuilder,
                            inviteTeammateViewBuilder: inviteTeammateViewBuilder,
                            requestRedeployViewBuilder: requestRedeployViewBuilder,
                            listsViewBuilder: listsViewBuilder,
                            syncInsightsViewBuilder: syncInsightsViewBuilder,
                            selectedTab: $selectedTab,
                            showTabDivider: !deviceSize.isLargeScreen,
                            dividerHeight: $dividerHeight,
                            dividerOffset: $dividerOffset
                        )
                    }
                }
            }

            if viewModel.showInactiveOrganization {
                InactiveOrganizationView(
                    viewModel: viewModel,
                    isNavigatingAuth: isNavigatingAuth
                )
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.onActivePhase()
            } else if newPhase == .background {
                viewModel.onBackgroundPhase()
            }
        }
        .onReceive(deviceSize.$isShort) { newValue in
            // TODO: Update values relative to tab bar height
            dividerHeight = newValue ? 16.0 : 32.0
            dividerOffset = newValue ? -6.0 : -6.0
        }
        .onChange(of: viewModel.showOnboarding) { newValue in
            if newValue,
               selectedTab != .menu {
                selectedTab = .menu
            }
        }
        .onChange(of: viewModel.viewData.showMainContent) { newValue in
            if newValue {
                clearAuthNavigation()
            }
        }
        .onChange(of: viewModel.viewData.areTokensValid) { newValue in
            if newValue && viewModel.showAuthScreen {
                clearAuthNavigation()
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environment(\.translator, viewModel.translator)
        .environment(\.font, .bodyLarge)
        .environmentObject(router)
        .environmentObject(appAlerts)
        .environmentObject(locationManager)
        .environmentObject(deviceSize)
    }
}

private struct TabViewContainer<Content: View>: View {
    let backgroundColor: Color

    private let content: Content

    init(
        backgroundColor: Color = appTheme.colors.navigationContainerColor,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack {
                content
            }
        }
    }
}

private struct MainTabs: View {
    @ObservedObject var viewModel: MainViewModel

    let openAuthScreen: () -> Void

    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder

    var body: some View {
        TabViewContainer {
            WorkTypeIconsView(viewModel.iconImages)
        }
        .navTabItem(.cases, viewModel.translator)
        .tag(TopLevelDestination.cases)

        TabViewContainer {
            menuViewBuilder.menuView(openAuthScreen)
        }
        .navTabItem(.menu, viewModel.translator)
        .tag(TopLevelDestination.menu)
    }
}

private struct AuthenticationNavigationStack: View {
    @EnvironmentObject var router: NavigationRouter

    var authenticateViewBuilder: AuthenticateViewBuilder
    var volunteerOrgViewBuilder: VolunteerOrgViewBuilder
    var exitAuthNavigation: () -> Void

    var body: some View {
        NavigationStack(path: $router.path) {
            authenticateViewBuilder.authenticateView(dismissScreen: exitAuthNavigation)
                .navigationDestination(for: NavigationRoute.self) { route in
                    switch route {
                    case .loginWithEmail:
                        authenticateViewBuilder.loginWithEmailView()
                    case .loginWithPhone:
                        authenticateViewBuilder.loginWithPhoneView
                    case .phoneLoginCode(let phoneNumber):
                        authenticateViewBuilder.phoneLoginCodeView(phoneNumber)
                    case .magicLinkLoginCode(let code):
                        authenticateViewBuilder.magicLinkLoginCodeView(code)
                    case .recoverPassword(let showForgotPassword, let showMagicLink):
                        authenticateViewBuilder.passwordRecoverView(
                            showForgotPassword: showForgotPassword,
                            showMagicLink: showMagicLink
                        )
                    case .resetPassword(let recoverCode):
                        authenticateViewBuilder.resetPasswordView(
                            closeAuthFlow: exitAuthNavigation,
                            resetCode: recoverCode
                        )
                    case .volunteerOrg:
                        volunteerOrgViewBuilder.volunteerOrgView
                    case .requestOrgAccess:
                        volunteerOrgViewBuilder.requestOrgAccessView
                    case .orgUserInvite(let inviteCode):
                        volunteerOrgViewBuilder.orgUserInviteView(inviteCode)
                    case .orgPersistentInvite(let invite):
                        volunteerOrgViewBuilder.orgPersistentInviteView(invite)
                    case .scanOrgQrCode:
                        volunteerOrgViewBuilder.scanQrCodeJoinOrgView
                    case .pasteOrgInviteLink:
                        volunteerOrgViewBuilder.pasteOrgInviteView
                    default:
                        Text("Pending auth/account route \(route.id)")
                    }
                }
        }
    }
}

private struct TermsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        let isFetchingTerms = viewModel.isFetchingTermsAcceptance
        if isFetchingTerms {
            ProgressView()
                .circularProgress()
        } else {
            AcceptTermsView(
                termsUrl: viewModel.termsOfServiceUrl,
                privacyUrl: viewModel.privacyPolicyUrl,
                isLoading: viewModel.isLoadingTermsAcceptance,
                onRequireCheckAcceptTerms: viewModel.onRequireCheckAcceptTerms,
                onRejectTerms: viewModel.onRejectTerms,
                onAcceptTerms: viewModel.onAcceptTerms,
                errorMessage: viewModel.acceptTermsErrorMessage
            )
        }
    }
}

private struct MainNavigationStack: View {
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: MainViewModel

    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder
    let casesFilterViewBuilder: CasesFilterViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder
    let viewCaseViewBuilder: ViewCaseViewBuilder
    let caseAddNoteViewBuilder: CaseAddNoteViewBuilder
    let createEditCaseViewBuilder: CreateEditCaseViewBuilder
    let caseShareViewBuilder: CaseShareViewBuilder
    let caseFlagsViewBuilder: CaseFlagsViewBuilder
    let caseHistoryViewBuilder: CaseHistoryViewBuilder
    let transferWorkTypeViewBuilder: TransferWorkTypeViewBuilder
    let viewImageViewBuilder: ViewImageViewBuilder
    let worksiteImagesViewBuilder: WorksiteImagesViewBuilder
    let caseSearchLocationViewBuilder: CaseSearchLocationViewBuilder
    let caseMoveOnMapViewBuilder: CaseMoveOnMapViewBuilder
    let userFeedbackViewBuilder: UserFeedbackViewBuilder
    let inviteTeammateViewBuilder: InviteTeammateViewBuilder
    let requestRedeployViewBuilder: RequestRedeployViewBuilder
    let listsViewBuilder: ListsViewBuilder
    let syncInsightsViewBuilder: SyncInsightsViewBuilder

    @Binding var selectedTab: TopLevelDestination

    let showTabDivider: Bool
    @Binding var dividerHeight: CGFloat
    @Binding var dividerOffset: CGFloat

    var body: some View {
        let iconColor = appTheme.colors.navigationContentColor
        let iconColorFaded = iconColor.opacity(0.65)
        NavigationStack(path: $router.path) {
            ZStack {
                TabView(selection: $selectedTab) {
                    let openAuthScreen = {
                        viewModel.showAuthScreen = true
                    }
                    MainTabs(
                        viewModel: viewModel,
                        openAuthScreen: openAuthScreen,
                        casesViewBuilder: casesViewBuilder,
                        menuViewBuilder: menuViewBuilder
                    )
                }
                .tabViewStyle(
                    backgroundColor: appTheme.colors.navigationContainerColor,
                    itemColor: iconColorFaded,
                    selectedItemColor: iconColor
                )
                .if (showTabDivider) {
                    $0.overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(width: 1, height: dividerHeight)
                            .overlay(iconColorFaded)
                            .offset(y: dividerOffset)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .filterCases:
                    casesFilterViewBuilder.casesFilterView
                case .searchCases:
                    casesSearchViewBuilder.casesSearchView
                        .navigationBarHidden(true)
                case .viewCase(let incidentId, let worksiteId):
                    viewCaseViewBuilder.viewCaseView(
                        incidentId: incidentId,
                        worksiteId: worksiteId
                    )
                case .caseAddNote:
                    caseAddNoteViewBuilder.caseAddNoteView
                case .createEditCase(let incidentId, let worksiteId):
                    createEditCaseViewBuilder.createEditCaseView(
                        incidentId: incidentId,
                        worksiteId: worksiteId
                    )
                case .caseSearchLocation:
                    caseSearchLocationViewBuilder.caseSearchLocationView
                case .caseMoveOnMap:
                    caseMoveOnMapViewBuilder.caseMoveOnMapView
                case .caseShare:
                    caseShareViewBuilder.caseShareView
                case .caseShareStep2:
                    caseShareViewBuilder.caseShareStep2View
                case .caseFlags(let isFromCaseEdit):
                    caseFlagsViewBuilder.caseFlagsView(isFromCaseEdit: isFromCaseEdit)
                case .caseHistory:
                    caseHistoryViewBuilder.caseHistoryView
                case .caseWorkTypeTransfer:
                    transferWorkTypeViewBuilder.transferWorkTypeView
                case .viewImage(let imageId, let isNetworkImage, let screenTitle):
                    viewImageViewBuilder.viewImageView(imageId, isNetworkImage, screenTitle)
                case .worksiteImages(let worksiteId, let imageId, let imageUri, let screenTitle):
                    worksiteImagesViewBuilder.worksiteImagesView(
                        worksiteId: worksiteId,
                        imageId: imageId,
                        imageUri: imageUri,
                        screenTitle: screenTitle
                    )
                case .userFeedback:
                    userFeedbackViewBuilder.userFeedbackView
                case .inviteTeammate:
                    inviteTeammateViewBuilder.inviteTeammateView
                case .requestRedeploy:
                    requestRedeployViewBuilder.requestRedeployView
                case .lists:
                    listsViewBuilder.listsView
                case .viewList(let listId):
                    listsViewBuilder.viewListView(listId)
                case .syncInsights:
                    if viewModel.isNotProduction {
                        syncInsightsViewBuilder.syncInsightsView
                    }
                default:
                    Text("Route \(route.id) needs implementing")
                }
            }
        }
    }
}

private struct InactiveOrganizationView: View {
    @Environment(\.translator) var t

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: MainViewModel
    var isNavigatingAuth: Bool

    var body: some View {
        AlertDialog(
            title: t.t("info.account_inactive"),
            positiveActionText: t.t("actions.ok"),
            negativeActionText: "",
            dismissDialog: {},
            positiveAction: {
                if !isNavigatingAuth {
                    router.clearRoutes()
                }
                viewModel.acknowledgeInactiveOrganization()
            }
        ) {
            Text(t.t("info.account_inactive_no_organization"))
        }
    }
}
