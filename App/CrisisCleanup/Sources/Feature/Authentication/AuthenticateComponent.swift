import Combine
import NeedleFoundation
import SwiftUI

public protocol AuthenticateViewBuilder {
    func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView
    func loginWithEmailView(dismissScreen: @escaping () -> Void) -> AnyView
    func passwordRecoverView(showForgotPassword: Bool, showMagicLink: Bool) -> AnyView
}

class AuthenticateComponent: Component<AppDependency> {
    internal var viewModel: AuthenticateViewModel? = nil
    internal var _loginWithEmailViewModel: LoginWithEmailViewModel? = nil
    internal var _passwordRecoverViewModel: PasswordRecoverViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let passwordRecoverId = NavigationRoute.recoverPassword().id
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.loginWithEmail.id) {
                    self._loginWithEmailViewModel = nil
                }
                if !pathIds.contains(passwordRecoverId) {
                    self._passwordRecoverViewModel = nil
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
}
