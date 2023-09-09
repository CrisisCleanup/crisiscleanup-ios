import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent,
                            AuthenticateViewBuilder,
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
                            CaseSearchLocationViewBuilder,
                            CaseMoveOnMapViewBuilder,
                            UserFeedbackViewBuilder,
                            SyncInsightsViewBuilder
{
    public let appEnv: AppEnv
    public let appSettingsProvider: AppSettingsProvider
    public let loggerFactory: AppLoggerFactory
    public let addressSearchRepository: AddressSearchRepository

    var mainViewModel: MainViewModel {
        MainViewModel(
            accountDataRepository: accountDataRepository,
            appSupportRepository: appSupportRepository,
            appVersionProvider: appVersionProvider,
            translationsRepository: languageTranslationsRepository,
            incidentSelector: incidentSelector,
            syncPuller: syncPuller,
            syncPusher: syncPusher,
            accountDataRefresher: accountDataRefresher,
            logger: loggerFactory.getLogger("main"),
            appEnv: appEnv
        )
    }

    private var routerObserver: RouterObserver {
        shared {
            AppRouteObserver()
        }
    }

    var navigationRouter: NavigationRouter {
        NavigationRouter(routerObserver: routerObserver)
    }

    public init(
        appEnv: AppEnv,
        appSettingsProvider: AppSettingsProvider,
        loggerFactory: AppLoggerFactory,
        addressSearchRepository: AddressSearchRepository
    ) {
        self.appEnv = appEnv
        self.appSettingsProvider = appSettingsProvider
        self.loggerFactory = loggerFactory
        self.addressSearchRepository = addressSearchRepository
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
            caseSearchLocationViewBuilder: self,
            caseMoveOnMapViewBuilder: self,
            userFeedbackViewBuilder: self,
            syncInsightsViewBuilder: self
        )
    }

    // MARK: Authenticate

    lazy var authenticateComponent: AuthenticateComponent = AuthenticateComponent(parent: self)

    public func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView {
        authenticateComponent.authenticateView(dismissScreen: dismissScreen)
    }

    // MARK: Incident select

    lazy var incidentSelectComponent: IncidentSelectComponent = IncidentSelectComponent(parent: self)

    public func incidentSelectView(onDismiss: @escaping () -> Void ) -> AnyView {
        incidentSelectComponent.incidentSelectView(onDismiss: onDismiss)
    }

    public func onIncidentSelectDismiss() {
        incidentSelectComponent.onIncidentSelectDismiss()
    }

    // MARK: Cases filter

    lazy var casesFilterComponent: CasesFilterComponent = CasesFilterComponent(parent: self, routerObserver: routerObserver)

    public var casesFilterView: AnyView { casesFilterComponent.casesFilterView }

    // MARK: Cases search

    lazy var casesSearchComponent: CasesSearchComponent = CasesSearchComponent(parent: self, routerObserver: routerObserver)

    public var casesSearchView: AnyView { casesSearchComponent.casesSearchView }

    // MARK: View Case

    lazy var viewCaseComponent: ViewCaseComponent = ViewCaseComponent(parent: self, routerObserver: routerObserver)

    public func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView {
        viewCaseComponent.viewCaseView(
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    // MARK: Case add note

    lazy var caseAddNoteComponent: CaseAddNoteComponent = CaseAddNoteComponent(parent: self, routerObserver: routerObserver)

    public var caseAddNoteView: AnyView { caseAddNoteComponent.caseAddNoteView }

    // MARK: Create/edit Case

    lazy var createEditCaseComponent: CreateEditCaseComponent = CreateEditCaseComponent(parent: self, routerObserver: routerObserver)

    public func createEditCaseView(incidentId: Int64, worksiteId: Int64?) -> AnyView {
        createEditCaseComponent.createEditCaseView(
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    // MARK: Case search location

    lazy var caseSearchLocationComponent: CaseSearchLocationComponent = CaseSearchLocationComponent(parent: self, routerObserver: routerObserver)

    public var caseSearchLocationView: AnyView { caseSearchLocationComponent.caseSearchLocationView }

    // MARK: Case move on map

    lazy var caseMoveOnMapComponent: CaseMoveOnMapComponent = CaseMoveOnMapComponent(parent: self, routerObserver: routerObserver)

    public var caseMoveOnMapView: AnyView { caseMoveOnMapComponent.caseMoveOnMapView }

    // MARK: Case share

    lazy var caseShareComponent: CaseShareComponent = CaseShareComponent(parent: self, routerObserver: routerObserver)

    public var caseShareView: AnyView { caseShareComponent.caseShareView }

    public var caseShareStep2View: AnyView { caseShareComponent.caseShareStep2View }

    // MARK: Case flags

    lazy var caseFlagsComponent: CaseFlagsComponent = CaseFlagsComponent(parent: self, routerObserver: routerObserver)

    public func caseFlagsView(isFromCaseEdit: Bool) -> AnyView { caseFlagsComponent.caseFlagsView(isFromCaseEdit: isFromCaseEdit) }

    // MARK: Case history

    lazy var caseHistoryComponent: CaseHistoryComponent = CaseHistoryComponent(parent: self, routerObserver: routerObserver)

    public var caseHistoryView: AnyView { caseHistoryComponent.caseHistoryView }

    // MARK: Transfer work type

    lazy var transferWorkTypeComponent: TransferWorkTypeComponent = TransferWorkTypeComponent(
        parent: self,
        routerObserver: routerObserver,
        transferWorkTypeProvider: transferWorkTypeProvider
    )

    public var transferWorkTypeView: AnyView { transferWorkTypeComponent.transferWorkTypeView }

    // MARK: View image

    lazy var viewImageComponent: ViewImageComponent = ViewImageComponent(parent: self, routerObserver: routerObserver)

    public func viewImageView(
        _ imageId: Int64,
        _ isNetworkImage: Bool,
        _ screenTitle: String
    ) -> AnyView {
        viewImageComponent.viewImageView(imageId, isNetworkImage, screenTitle)
    }

    // MARK: User feedback

    lazy var userFeedbackComponent: UserFeedbackComponent = UserFeedbackComponent(parent: self, routerObserver: routerObserver)

    public var userFeedbackView: AnyView { userFeedbackComponent.userFeedbackView }

    // MARK: Sync insights

    lazy var syncInsightsComponent: SyncInsightsComponent = SyncInsightsComponent(parent: self, routerObserver: routerObserver)

    public var syncInsightsView: AnyView { syncInsightsComponent.syncInsightsView }
}
