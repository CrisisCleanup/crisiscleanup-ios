import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent {
    var mainViewModel: MainViewModel {
        MainViewModel()
    }

    public var mainView: some View {
        NavigationView {
            MainView(
                viewModel: mainViewModel,
                menuBuilder: menuComponent
            )
        }
    }

    var menuComponent: MenuComponent {
        return MenuComponent(parent: self)
    }
}
