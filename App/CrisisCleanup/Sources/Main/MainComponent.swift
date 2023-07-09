import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent,
                            AuthenticateViewBuilder,
                            IncidentSelectViewBuilder,
                            CasesFilterViewBuilder,
                            CasesSearchViewBuilder,
                            ViewCaseViewBuilder
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
            authenticateViewBuilder: self,
            casesViewBuilder: casesComponent,
            menuViewBuilder: menuComponent,
            casesFilterViewBuilder: casesFilterViewBuilder,
            casesSearchViewBuilder: casesSearchViewBuilder,
            viewCaseViewBuilder: viewCaseViewBuilder
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
}
