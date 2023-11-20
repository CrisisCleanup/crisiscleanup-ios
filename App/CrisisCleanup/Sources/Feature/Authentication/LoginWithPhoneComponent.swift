import SwiftUI

extension AuthenticateComponent {
    private var loginWithPhoneViewModel: LoginWithPhoneViewModel {
        if _loginWithPhoneViewModel == nil {
            _loginWithPhoneViewModel = LoginWithPhoneViewModel(
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
        return _loginWithPhoneViewModel!
    }

    func loginWithPhoneView(closeAuthFlow: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self._loginWithPhoneViewModel = nil
            closeAuthFlow()
        }
        return AnyView(
            LoginWithPhoneView(
                viewModel: loginWithPhoneViewModel,
                dismiss: clearViewModelOnHide
            )
        )
    }
}
