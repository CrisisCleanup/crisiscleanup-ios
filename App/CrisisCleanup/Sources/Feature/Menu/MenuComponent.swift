import NeedleFoundation
import SwiftUI

protocol MenuViewBuilder {
    var menuView: AnyView { get }
}

class MenuComponent: Component<AppDependency>, MenuViewBuilder {
    lazy var menuViewModel: MenuViewModel = {
        MenuViewModel(
            appEnv: dependency.appEnv,
            accountDataRepository: dependency.accountDataRepository,
            incidentSelector: dependency.incidentSelector,
            appVersionProvider: dependency.appVersionProvider,
            databaseVersionProvider: dependency.databaseVersionProvider,
            authEventBus: dependency.authEventBus,
            loggerFactory: dependency.loggerFactory
        )
    }()

    var menuView: AnyView {
        AnyView(
            MenuView(
                viewModel: menuViewModel,
                authenticateViewBuilder: dependency.authenticateViewBuilder,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder
            )
        )
    }
}
