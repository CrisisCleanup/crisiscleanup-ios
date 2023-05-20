import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent {
    public private(set) var appEnv: AppEnv
    public private(set) var appSettingsProvider: AppSettingsProvider

    var mainViewModel: MainViewModel {
        MainViewModel()
    }

    public init(
        appEnv: AppEnv,
        appSettingsProvider: AppSettingsProvider
    ) {
        self.appEnv = appEnv
        self.appSettingsProvider = appSettingsProvider
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
