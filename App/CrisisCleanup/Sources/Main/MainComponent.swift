import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent {
    public private(set) var appEnv: AppEnv
    public private(set) var appSettingsProvider: AppSettingsProvider
    public private(set) var loggerFactory: AppLoggerFactory

    var mainViewModel: MainViewModel {
        MainViewModel(
            logger: loggerFactory.getLogger("main")
        )
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

    public var mainView: some View {
        MainView(
            viewModel: mainViewModel,
            menuViewBuilder: menuComponent
        )
    }

    var menuComponent: MenuComponent { MenuComponent(parent: self) }
}
