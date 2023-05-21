import NeedleFoundation
import SwiftUI

protocol MenuViewBuilder {
    var menuView: AnyView { get }
}

protocol AuthenticateViewBuilder {
    var authenticateView: AnyView { get }
}

class MenuComponent: Component<AppDependency>, MenuViewBuilder, AuthenticateViewBuilder {
    var menuViewModel: MenuViewModel {
        MenuViewModel(
            appEnv: dependency.appEnv,
            appVersionProvider: dependency.appVersionProvider,
            loggerFactory: dependency.loggerFactory
        )
    }

    var authenticateViewModel: AuthenticateViewModel {
        AuthenticateViewModel(
            appEnv: dependency.appEnv,
            loggerFactory: dependency.loggerFactory
        )
    }

    var menuView: AnyView {
        AnyView(
            MenuView(
                viewModel: menuViewModel,
                authenticateViewBuilder: self
            )
        )
    }

    var authenticateView: AnyView {
        AnyView(
            AuthenticateView(
                viewModel: authenticateViewModel
            )
        )
    }

    var authenticateComponent: AuthenticateComponent { AuthenticateComponent(parent: self) }
}
