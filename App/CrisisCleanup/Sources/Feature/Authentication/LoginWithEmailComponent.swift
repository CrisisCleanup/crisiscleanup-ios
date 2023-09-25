import NeedleFoundation
import SwiftUI

public protocol LoginWithEmailViewBuilder {
    func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView
}

class LoginWithEmailComponent: Component<AppDependency> {
    private var viewModel: LoginWithEmailViewModel? = nil

    private var loginWithEmailViewModel: LoginWithEmailViewModel {
        if viewModel == nil {
            viewModel = LoginWithEmailViewModel(
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
        return viewModel!
    }

    func loginWithEmailView(dismissScreen: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self.viewModel = nil
            dismissScreen()
        }
        return AnyView(
            LoginWithEmailView(
                viewModel: loginWithEmailViewModel,
                dismiss: clearViewModelOnHide
            )
        )
    }
}
