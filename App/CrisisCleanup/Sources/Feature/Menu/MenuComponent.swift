import NeedleFoundation
import SwiftUI

protocol MenuViewBuilder {
    var menuView: AnyView { get }
}

class MenuComponent: Component<AppDependency>, MenuViewBuilder {
    var menuViewModel: MenuViewModel {
        MenuViewModel(
            appEnv: dependency.appEnv,
            accountDataRepository: dependency.accountDataRepository,
            appVersionProvider: dependency.appVersionProvider,
            authEventBus: dependency.authEventBus,
            loggerFactory: dependency.loggerFactory
        )
    }

    var menuView: AnyView {
        AnyView(
            MenuView(
                viewModel: menuViewModel,
                authenticateViewBuilder: dependency.authenticateViewBuilder
            )
        )
    }
}
