import NeedleFoundation
import SwiftUI

protocol MenuBuilder {
    var menuView: AnyView { get }
}

class MenuComponent: Component<AppVersionDependency>, MenuBuilder {
    var menuViewModel: MenuViewModel {
        MenuViewModel(appVersionProvider: dependency.appVersionProvider)
    }

    var menuView: AnyView {
        AnyView(
            MenuView(viewModel: menuViewModel)
        )
    }
}
