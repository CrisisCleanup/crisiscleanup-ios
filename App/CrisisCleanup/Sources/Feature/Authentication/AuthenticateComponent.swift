import Combine
import NeedleFoundation
import SwiftUI

public protocol AuthenticateViewBuilder {
    func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView
    func loginWithEmailView(dismissScreen: @escaping () -> Void) -> AnyView
}

class AuthenticateComponent: Component<AppDependency> {
    private var viewModel: AuthenticateViewModel? = nil
    private var _loginWithEmailViewModel: LoginWithEmailViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.loginWithEmail.id) {
                    self._loginWithEmailViewModel = nil
                }
            }
            .store(in: &disposables)
    }

    private var authenticateViewModel: AuthenticateViewModel {
        if viewModel == nil {
            viewModel = AuthenticateViewModel(
                accountDataRepository: dependency.accountDataRepository,
                authEventBus: dependency.authEventBus
            )
        }
        return viewModel!
    }

    func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self.viewModel = nil
            dismissScreen()
        }
        return AnyView(
            AuthenticateView(
                viewModel: authenticateViewModel,
                dismiss: clearViewModelOnHide
            )
        )
    }


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
