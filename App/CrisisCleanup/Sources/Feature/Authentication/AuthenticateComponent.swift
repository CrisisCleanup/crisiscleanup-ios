import NeedleFoundation
import SwiftUI

class AuthenticateComponent: Component<AppDependency> {
    private var authenticateViewModel: AuthenticateViewModel {
        AuthenticateViewModel(
            appEnv: dependency.appEnv,
            appSettings: dependency.appSettingsProvider,
            authApi: dependency.authApi,
            inputValidator: dependency.inputValidator,
            accessTokenDecoder: accessTokenDecoder,
            accountDataRepository: dependency.accountDataRepository,
            authEventBus: dependency.authEventBus,
            translator: dependency.translator,
            loggerFactory: dependency.loggerFactory
        )
    }

    var authenticateView: AnyView {
        AnyView(
            AuthenticateView(
                viewModel: authenticateViewModel
            )
        )
    }
}
