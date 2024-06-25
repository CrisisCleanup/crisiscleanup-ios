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

    func loginWithEmailView() -> AnyView {
        AnyView(
            LoginWithEmailView(
                viewModel: loginWithEmailViewModel
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
                authApi: dependency.authApi,
                dataApi: dependency.networkDataSource,
                accountDataRepository: dependency.accountDataRepository,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                authCode: code
            )
        }
        return _loginWithMagicLinkViewModel!
    }

    func magicLinkLoginCodeView(_ code: String) -> AnyView {
        AnyView(
            LoginMagicLinkCodeView(
                viewModel: loginWithMagicLinkViewModel(code)
            )
        )
    }
}
