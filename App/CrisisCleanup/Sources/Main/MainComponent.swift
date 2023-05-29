import NeedleFoundation
import SwiftUI

public class MainComponent: BootstrapComponent, AuthenticateViewBuilder {
    public private(set) var appEnv: AppEnv
    public private(set) var appSettingsProvider: AppSettingsProvider
    public private(set) var loggerFactory: AppLoggerFactory

    var mainViewModel: MainViewModel {
        MainViewModel(
            accountDataRepository: accountDataRepository,
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

    var menuComponent: MenuComponent { MenuComponent(parent: self) }

    public var mainView: some View {
        MainView(
            viewModel: mainViewModel,
            authenticateViewBuilder: self,
            menuViewBuilder: menuComponent
        )
    }

    var authenticateComponent: AuthenticateComponent { AuthenticateComponent(parent: self) }

    public var authenticateView: AnyView {
        AnyView(
            AuthenticateView(
                viewModel: authenticateComponent.authenticateViewModel
            )
        )
    }
}
