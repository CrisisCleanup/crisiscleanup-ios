import NeedleFoundation
import SwiftUI

protocol MenuBuilder {
    var menuView: AnyView { get }
}

class MenuComponent: Component<AppDependency>, MenuBuilder {
    var menuViewModel: MenuViewModel {
        MenuViewModel(
            appEnv: dependency.appEnv,
            appVersionProvider: dependency.appVersionProvider
        )
    }

    var menuView: AnyView {
        AnyView(
            MenuView(viewModel: menuViewModel)
        )
    }
}
