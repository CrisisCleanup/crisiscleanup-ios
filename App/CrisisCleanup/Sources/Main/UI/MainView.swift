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
    let caseSearchLocationViewBuilder: CaseSearchLocationViewBuilder
    let caseMoveOnMapViewBuilder: CaseMoveOnMapViewBuilder
    let userFeedbackViewBuilder: UserFeedbackViewBuilder
    let inviteTeammateViewBuilder: InviteTeammateViewBuilder
    let syncInsightsViewBuilder: SyncInsightsViewBuilder

    @State private var selectedTab = TopLevelDestination.cases

    var body: some View {
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
                if viewModel.showAuthScreen ||
                    !viewModel.viewData.showMainContent {
                    NavigationStack(path: $router.path) {
                        authenticateViewBuilder.authenticateView(dismissScreen: hideAuthScreen)
                            .navigationDestination(for: NavigationRoute.self) { route in
                                switch route {
                                case .loginWithEmail:
                                    authenticateViewBuilder.loginWithEmailView(closeAuthFlow: hideAuthScreen)
                                case .loginWithPhone:
                                    authenticateViewBuilder.loginWithPhoneView
                                case .phoneLoginCode(let phoneNumber):
                                    authenticateViewBuilder.phoneLoginCodeView(
                                        phoneNumber,
                                        closeAuthFlow: hideAuthScreen
                                    )
                                case .magicLinkLoginCode(let code):
                                    authenticateViewBuilder.magicLinkLoginCodeView(
                                        code,
                                        closeAuthFlow: hideAuthScreen
                                    )
                                case .recoverPassword(let showForgotPassword, let showMagicLink):
                                    authenticateViewBuilder.passwordRecoverView(
                                        showForgotPassword: showForgotPassword,
                                        showMagicLink: showMagicLink
                                    )
                                case .resetPassword(let recoverCode):
                                    authenticateViewBuilder.resetPasswordView(
                                        closeAuthFlow: hideAuthScreen,
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
                } else if !viewModel.viewData.hasAcceptedTerms {
                    ZStack {
                        let isFetchingTerms = viewModel.isFetchingTermsAcceptance
                        if !isFetchingTerms {
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

                        if isFetchingTerms {
                            ProgressView()
                                .circularProgress()
                        }
                    }
                } else {
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
                                selectedItemColor: .white
                            )
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
                            case .userFeedback:
                                userFeedbackViewBuilder.userFeedbackView
                            case .inviteTeammate:
                                inviteTeammateViewBuilder.inviteTeammateView
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
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.onActivePhase()
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environment(\.translator, viewModel.translator)
        .environment(\.font, .bodyLarge)
        .environmentObject(router)
        .environmentObject(appAlerts)
        .environmentObject(locationManager)
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
            casesViewBuilder.casesView(openAuthScreen)
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
