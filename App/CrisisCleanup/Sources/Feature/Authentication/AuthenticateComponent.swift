import NeedleFoundation
import SwiftUI

class AuthenticateComponent: Component<AppDependency> {
    var authenticateViewModel: AuthenticateViewModel {
        AuthenticateViewModel(
            appEnv: dependency.appEnv,
            appSettings: dependency.appSettingsProvider,
            authApi: dependency.authApi,
            inputValidator: dependency.inputValidator,
            accessTokenDecoder: accessTokenDecoder,
            accountDataRepository: dependency.accountDataRepository,
            authEventBus: dependency.authEventBus,
            loggerFactory: dependency.loggerFactory
        )
    }

    var authenticateView: some View {
        AuthenticateView(
            viewModel: authenticateViewModel
        )
    }
}
