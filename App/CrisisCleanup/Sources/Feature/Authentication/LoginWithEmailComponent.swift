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
            self._loginWithEmailViewModel = nil
            closeAuthFlow()
        }
        return AnyView(
            LoginWithEmailView(
                viewModel: loginWithEmailViewModel,
                dismiss: clearViewModelOnHide
            )
        )
    }

    private func loginWithMagicLinkViewModel(_ code: String) -> LoginWithMagicLinkViewModel {
        var isReusable = false
        if let vm = _loginWithMagicLinkViewModel {
            isReusable = vm.authCode == code
        }

        if !isReusable {
            _loginWithMagicLinkViewModel = LoginWithMagicLinkViewModel(
                appSettings: dependency.appSettingsProvider,
                authApi: dependency.authApi,
                dataApi: dependency.networkDataSource,
                accessTokenDecoder: dependency.accessTokenDecoder,
                accountDataRepository: dependency.accountDataRepository,
                authEventBus: dependency.authEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                authCode: code
            )
        }
        return _loginWithMagicLinkViewModel!
    }

    func magicLinkLoginCodeView(_ code: String, closeAuthFlow: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self._loginWithMagicLinkViewModel = nil
            closeAuthFlow()
        }
        return AnyView(
            LoginMagicLinkCodeView(
                viewModel: loginWithMagicLinkViewModel(code),
                dismiss: clearViewModelOnHide
            )
        )
    }
}
