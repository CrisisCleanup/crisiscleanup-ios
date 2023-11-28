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
                accountUpdateRepository: dependency.accountUpdateRepository,
                accountDataRepository: dependency.accountDataRepository,
                authEventBus: dependency.authEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return _loginWithPhoneViewModel!
    }

    var loginWithPhoneView: AnyView {
        AnyView(
            LoginWithPhoneView(
                viewModel: loginWithPhoneViewModel
            )
        )
    }

    func phoneLoginCodeView(_ phoneNumber: String, closeAuthFlow: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self._loginWithPhoneViewModel = nil
            closeAuthFlow()
        }
        return AnyView(
            LoginPhoneCodeView(
                viewModel: loginWithPhoneViewModel,
                dismiss: clearViewModelOnHide
            )
        )
    }
}
