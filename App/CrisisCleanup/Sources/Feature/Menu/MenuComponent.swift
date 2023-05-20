import NeedleFoundation
import SwiftUI

protocol MenuBuilder {
    var menuView: AnyView { get }
}

class MenuComponent: Component<EmptyDependency>, MenuBuilder {
    var menuViewModel: MenuViewModel {
        MenuViewModel()
    }

    var menuView: AnyView {
        AnyView(
            MenuView(viewModel: menuViewModel)
        )
    }
}
