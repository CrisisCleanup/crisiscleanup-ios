import SwiftUI

extension AuthenticateComponent {
    private var loginWithEmailViewModel: LoginWithEmailViewModel {
        if _loginWithEmailViewModel == nil {
            _loginWithEmailViewModel = LoginWithEmailViewModel(
                appEnv: dependency.appEnv,
                appSettings: dependency.appSettingsProvider,
                authApi: dependency.authApi,
                inputValidator: dependency.inputValidator,
                accessTokenDecoder: dependency.accessTokenDecoder,
                accountDataRepository: dependency.accountDataRepository,
                authEventBus: dependency.authEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return _loginWithEmailViewModel!
    }

    func loginWithEmailView(closeAuthFlow: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self.viewModel = nil
            closeAuthFlow()
        }
        return AnyView(
            LoginWithEmailView(
                viewModel: loginWithEmailViewModel,
                dismiss: clearViewModelOnHide
            )
        )
    }
}
