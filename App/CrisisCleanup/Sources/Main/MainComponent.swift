import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent,
                            AuthenticateViewBuilder,
                            IncidentSelectViewBuilder,
                            CasesFilterViewBuilder,
                            CasesSearchViewBuilder,
                            ViewCaseViewBuilder,
                            CreateEditCaseViewBuilder,
                            CaseShareViewBuilder,
                            CaseFlagsViewBuilder,
                            CaseHistoryViewBuilder,
                            TransferWorkTypeViewBuilder
{
    public private(set) var appEnv: AppEnv
    public private(set) var appSettingsProvider: AppSettingsProvider
    public private(set) var loggerFactory: AppLoggerFactory

    var mainViewModel: MainViewModel {
        MainViewModel(
            accountDataRepository: accountDataRepository,
            translationsRepository: languageTranslationsRepository,
            incidentSelector: incidentSelector,
            syncPuller: syncPuller,
            logger: loggerFactory.getLogger("main")
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
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.appSettingsProvider = appSettingsProvider
        self.loggerFactory = loggerFactory
    }

    var casesComponent: CasesComponent { CasesComponent(parent: self) }
    var menuComponent: MenuComponent { MenuComponent(parent: self) }

    public var mainView: some View {
        MainView(
            viewModel: mainViewModel,
            router: navigationRouter,
            authenticateViewBuilder: authenticateViewBuilder,
            casesViewBuilder: casesComponent,
            menuViewBuilder: menuComponent,
            casesFilterViewBuilder: self,
            casesSearchViewBuilder: self,
            viewCaseViewBuilder: self,
            createEditCaseViewBuilder: self,
            caseShareViewBuilder: self,
            caseFlagsViewBuilder: self,
            caseHistoryViewBuilder: self,
            transferWorkTypeViewBuilder: self
        )
    }

    // MARK: Authenticate

    var authenticateComponent: AuthenticateComponent { AuthenticateComponent(parent: self) }

    public var authenticateView: AnyView { authenticateComponent.authenticateView }

    // MARK: Incident select

    lazy var incidentSelectComponent: IncidentSelectComponent = {
        IncidentSelectComponent(parent: self)
    }()

    public func incidentSelectView(onDismiss: @escaping () -> Void ) -> AnyView {
        incidentSelectComponent.incidentSelectView(onDismiss: onDismiss)
    }

    public func onIncidentSelectDismiss() {
        incidentSelectComponent.onIncidentSelectDismiss()
    }

    // MARK: Cases filter

    lazy var casesFilterComponent: CasesFilterComponent = { CasesFilterComponent(parent: self) }()

    public var casesFilterView: AnyView { casesFilterComponent.casesFilterView }

    // MARK: Cases search

    lazy var casesSearchComponent: CasesSearchComponent = { CasesSearchComponent(parent: self, routerObserver: routerObserver)
    }()

    public var casesSearchView: AnyView { casesSearchComponent.casesSearchView }

    // MARK: View Case

    lazy var viewCaseComponent: ViewCaseComponent = { ViewCaseComponent(parent: self, routerObserver: routerObserver)
    }()

    public func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView {
        viewCaseComponent.viewCaseView(
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    // MARK: Create/edit Case

    lazy var createEditCaseComponent: CreateEditCaseComponent = { CreateEditCaseComponent(parent: self, routerObserver: routerObserver)
    }()

    public func createEditCaseView(incidentId: Int64, worksiteId: Int64?) -> AnyView {
        createEditCaseComponent.createEditCaseView(
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    // MARK: Case share

    lazy var caseShareComponent: CaseShareComponent = {
        CaseShareComponent(parent: self, routerObserver: routerObserver)
    }()

    public var caseShareView: AnyView { caseShareComponent.caseShareView }

    // MARK: Case flags

    lazy var caseFlagsComponent: CaseFlagsComponent = {
        CaseFlagsComponent(parent: self, routerObserver: routerObserver)
    }()

    public var caseFlagsView: AnyView { caseFlagsComponent.caseFlagsView }

    // MARK: Case history

    lazy var caseHistoryComponent: CaseHistoryComponent = {
        CaseHistoryComponent(parent: self, routerObserver: routerObserver)
    }()

    public var caseHistoryView: AnyView { caseHistoryComponent.caseHistoryView }

    // MARK: Transfer work type

    lazy var transferWorkTypeComponent: TransferWorkTypeComponent = {
        TransferWorkTypeComponent(
            parent: self,
            routerObserver: routerObserver,
            transferWorkTypeProvider: transferWorkTypeProvider
        )
    }()

    public var transferWorkTypeView: AnyView { transferWorkTypeComponent.transferWorkTypeView }
}
