import NeedleFoundation
import SwiftUI

protocol MenuViewBuilder {
    func menuView(_ openAuthScreen: @escaping () -> Void) -> AnyView
}

class MenuComponent: Component<AppDependency>, MenuViewBuilder {
    lazy var menuViewModel: MenuViewModel = MenuViewModel(
        appEnv: dependency.appEnv,
        accountDataRepository: dependency.accountDataRepository,
        accountDataRefresher: dependency.accountDataRefresher,
        syncLogRepository: dependency.syncLogRepository,
        incidentSelector: dependency.incidentSelector,
        appVersionProvider: dependency.appVersionProvider,
        databaseVersionProvider: dependency.databaseVersionProvider,
        authEventBus: dependency.authEventBus,
        loggerFactory: dependency.loggerFactory
    )

    func menuView(_ openAuthScreen: @escaping () -> Void) -> AnyView {
        AnyView(
            MenuView(
                viewModel: menuViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen
            )
        )
    }
}
