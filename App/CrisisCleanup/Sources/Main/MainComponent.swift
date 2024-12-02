import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent,
                            AuthenticateViewBuilder,
                            VolunteerOrgViewBuilder,
                            IncidentSelectViewBuilder,
                            CasesFilterViewBuilder,
                            CasesSearchViewBuilder,
                            ViewCaseViewBuilder,
                            CaseAddNoteViewBuilder,
                            CreateEditCaseViewBuilder,
                            CaseShareViewBuilder,
                            CaseFlagsViewBuilder,
                            CaseHistoryViewBuilder,
                            TransferWorkTypeViewBuilder,
                            ViewImageViewBuilder,
                            WorksiteImagesViewBuilder,
                            CaseSearchLocationViewBuilder,
                            CaseMoveOnMapViewBuilder,
                            UserFeedbackViewBuilder,
                            InviteTeammateViewBuilder,
                            RequestRedeployViewBuilder,
                            ListsViewBuilder,
                            SyncInsightsViewBuilder
{
    public let appEnv: AppEnv
    public let appSettingsProvider: AppSettingsProvider
    public let loggerFactory: AppLoggerFactory
    public let addressSearchRepository: AddressSearchRepository
    public let externalEventBus: ExternalEventBus

    lazy var mainViewModel: MainViewModel = MainViewModel(
        accountDataRepository: accountDataRepository,
        appSupportRepository: appSupportRepository,
        appVersionProvider: appVersionProvider,
        appPreferences: appPreferences,
        appSettingsProvider: appSettingsProvider,
        translationsRepository: languageTranslationsRepository,
        incidentSelector: incidentSelector,
        appDataRepository: appDataManagementRepository,
        externalEventBus: externalEventBus,
        accountEventBus: accountEventBus,
        navigationRouter: navigationRouter,
        syncPuller: syncPuller,
        syncPusher: syncPusher,
        accountDataRefresher: accountDataRefresher,
        accountUpdateRepository: accountUpdateRepository,
        shareLocationRepository: shareLocationRepository,
        networkMonitor: networkMonitor,
        logger: loggerFactory.getLogger("main"),
        appEnv: appEnv
    )

    private var routerObserver: RouterObserver {
        shared {
            AppRouteObserver()
        }
    }

    var navigationRouter: NavigationRouter {
        shared {
            NavigationRouter(routerObserver: routerObserver)
        }
    }

    public init(
        appEnv: AppEnv,
        appSettingsProvider: AppSettingsProvider,
        loggerFactory: AppLoggerFactory,
        addressSearchRepository: AddressSearchRepository,
        externalEventBus: ExternalEventBus
    ) {
        self.appEnv = appEnv
        self.appSettingsProvider = appSettingsProvider
        self.loggerFactory = loggerFactory
        self.addressSearchRepository = addressSearchRepository
        self.externalEventBus = externalEventBus
    }

    var casesComponent: CasesComponent { CasesComponent(parent: self) }
    var menuComponent: MenuComponent { MenuComponent(parent: self) }

    public var mainView: some View {
        MainView(
            viewModel: mainViewModel,
            router: navigationRouter,
            appAlerts: AppAlertViewState(
                networkMonitor: networkMonitor,
                accountDataRepository: accountDataRepository
            ),
            locationManager: locationManager,
            authenticateViewBuilder: authenticateViewBuilder,
            volunteerOrgViewBuilder: self,
            casesViewBuilder: casesComponent,
            menuViewBuilder: menuComponent,
            casesFilterViewBuilder: self,
            casesSearchViewBuilder: self,
            viewCaseViewBuilder: self,
            caseAddNoteViewBuilder: self,
            createEditCaseViewBuilder: self,
            caseShareViewBuilder: self,
            caseFlagsViewBuilder: self,
            caseHistoryViewBuilder: self,
            transferWorkTypeViewBuilder: self,
            viewImageViewBuilder: self,
            worksiteImagesViewBuilder: self,
            caseSearchLocationViewBuilder: self,
            caseMoveOnMapViewBuilder: self,
            userFeedbackViewBuilder: self,
            inviteTeammateViewBuilder: self,
            requestRedeployViewBuilder: self,
            listsViewBuilder: self,
            syncInsightsViewBuilder: self
        )
    }

    // MARK: Authenticate, onboarding

    lazy var authenticateComponent = AuthenticateComponent(parent: self, routerObserver: routerObserver)

    public func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView {
        authenticateComponent.authenticateView(dismissScreen: dismissScreen)
    }

    public func loginWithEmailView() -> AnyView {
        authenticateComponent.loginWithEmailView()
    }

    public var loginWithPhoneView: AnyView { authenticateComponent.loginWithPhoneView }

    public func phoneLoginCodeView(_ phoneNumber: String) -> AnyView {
        authenticateComponent.phoneLoginCodeView(phoneNumber)
    }

    public func magicLinkLoginCodeView(_ code: String) -> AnyView {
        authenticateComponent.magicLinkLoginCodeView(code)
    }

    public func passwordRecoverView(showForgotPassword: Bool, showMagicLink: Bool) -> AnyView {
        authenticateComponent.passwordRecoverView(showForgotPassword: showForgotPassword, showMagicLink: showMagicLink)
    }

    public func resetPasswordView(closeAuthFlow: @escaping () -> Void, resetCode: String) -> AnyView {
        authenticateComponent.resetPasswordView(
            closeAuthFlow: closeAuthFlow,
            resetCode: resetCode
        )
    }

    lazy var volunteerOrgComponent = VolunteerOrgComponent(parent: self, routerObserver: routerObserver)

    public var volunteerOrgView: AnyView { volunteerOrgComponent.volunteerOrgView }

    public var requestOrgAccessView: AnyView { volunteerOrgComponent.requestOrgAccessView }

    public func orgUserInviteView(_ code: String) -> AnyView { volunteerOrgComponent.orgUserInviteView(code) }

    public func orgPersistentInviteView(_ invite: UserPersistentInvite) -> AnyView {
        volunteerOrgComponent.orgPersistentInviteView(invite)
    }

    public var scanQrCodeJoinOrgView: AnyView { volunteerOrgComponent.scanQrCodeJoinOrgView }

    public var pasteOrgInviteView: AnyView { volunteerOrgComponent.pasteOrgInviteView }

    // MARK: Incident select

    lazy var incidentSelectComponent = IncidentSelectComponent(parent: self)

    public func incidentSelectView(onDismiss: @escaping () -> Void ) -> AnyView {
        incidentSelectComponent.incidentSelectView(onDismiss: onDismiss)
    }

    public func onIncidentSelectDismiss() {
        incidentSelectComponent.onIncidentSelectDismiss()
    }

    // MARK: Cases filter

    lazy var casesFilterComponent = CasesFilterComponent(parent: self, routerObserver: routerObserver)

    public var casesFilterView: AnyView { casesFilterComponent.casesFilterView }

    // MARK: Cases search

    lazy var casesSearchComponent = CasesSearchComponent(parent: self, routerObserver: routerObserver)

    public var casesSearchView: AnyView { casesSearchComponent.casesSearchView }

    // MARK: View Case

    lazy var viewCaseComponent = ViewCaseComponent(parent: self, routerObserver: routerObserver)

    public func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView {
        viewCaseComponent.viewCaseView(
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    // MARK: Case add note

    lazy var caseAddNoteComponent = CaseAddNoteComponent(parent: self, routerObserver: routerObserver)

    public var caseAddNoteView: AnyView { caseAddNoteComponent.caseAddNoteView }

    // MARK: Create/edit Case

    lazy var createEditCaseComponent = CreateEditCaseComponent(parent: self, routerObserver: routerObserver)

    public func createEditCaseView(incidentId: Int64, worksiteId: Int64?) -> AnyView {
        createEditCaseComponent.createEditCaseView(
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    // MARK: Case search location

    lazy var caseSearchLocationComponent = CaseSearchLocationComponent(parent: self, routerObserver: routerObserver)

    public var caseSearchLocationView: AnyView { caseSearchLocationComponent.caseSearchLocationView }

    // MARK: Case move on map

    lazy var caseMoveOnMapComponent = CaseMoveOnMapComponent(parent: self, routerObserver: routerObserver)

    public var caseMoveOnMapView: AnyView { caseMoveOnMapComponent.caseMoveOnMapView }

    // MARK: Case share

    lazy var caseShareComponent = CaseShareComponent(parent: self, routerObserver: routerObserver)

    public var caseShareView: AnyView { caseShareComponent.caseShareView }

    public var caseShareStep2View: AnyView { caseShareComponent.caseShareStep2View }

    // MARK: Case flags

    lazy var caseFlagsComponent = CaseFlagsComponent(parent: self, routerObserver: routerObserver)

    public func caseFlagsView(isFromCaseEdit: Bool) -> AnyView { caseFlagsComponent.caseFlagsView(isFromCaseEdit: isFromCaseEdit) }

    // MARK: Case history

    lazy var caseHistoryComponent = CaseHistoryComponent(parent: self, routerObserver: routerObserver)

    public var caseHistoryView: AnyView { caseHistoryComponent.caseHistoryView }

    // MARK: Transfer work type

    lazy var transferWorkTypeComponent = TransferWorkTypeComponent(
        parent: self,
        routerObserver: routerObserver,
        transferWorkTypeProvider: transferWorkTypeProvider
    )

    public var transferWorkTypeView: AnyView { transferWorkTypeComponent.transferWorkTypeView }

    // MARK: View image

    lazy var viewImageComponent = ViewImageComponent(parent: self, routerObserver: routerObserver)

    public func viewImageView(
        _ imageId: Int64,
        _ isNetworkImage: Bool,
        _ screenTitle: String
    ) -> AnyView {
        viewImageComponent.viewImageView(imageId, isNetworkImage, screenTitle)
    }

    lazy var worksiteImagesComponent = WorksiteImagesComponent(parent: self, routerObserver: routerObserver)

    public func worksiteImagesView(
        worksiteId: Int64,
        imageId: Int64,
        imageUri: String,
        screenTitle: String
    ) -> AnyView {
        worksiteImagesComponent.worksiteImagesView(
            worksiteId: worksiteId,
            imageId: imageId,
            imageUri: imageUri,
            screenTitle: screenTitle
        )
    }

    // MARK: User feedback

    lazy var userFeedbackComponent = UserFeedbackComponent(parent: self, routerObserver: routerObserver)

    public var userFeedbackView: AnyView { userFeedbackComponent.userFeedbackView }

    // MARK: Organization

    lazy var inviteTeammateComponent = InviteTeammateComponent(parent: self, routerObserver: routerObserver)

    public var inviteTeammateView: AnyView { inviteTeammateComponent.inviteTeammateView }

    lazy var requestRedeployComponent = RequestRedeployComponent(parent: self, routerObserver: routerObserver)

    public var requestRedeployView: AnyView { requestRedeployComponent.requestRedeployView }

    // MARK: Lists

    lazy var listsComponent = ListsComponent(parent: self, routerObserver: routerObserver)

    public var listsView: AnyView { listsComponent.listsView }

    public func viewListView(_ listId: Int64) -> AnyView { listsComponent.viewListView(listId) }

    // MARK: Sync insights

    lazy var syncInsightsComponent = SyncInsightsComponent(parent: self, routerObserver: routerObserver)

    public var syncInsightsView: AnyView { syncInsightsComponent.syncInsightsView }
}
