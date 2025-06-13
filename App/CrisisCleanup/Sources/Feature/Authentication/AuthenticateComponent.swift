import Combine
import NeedleFoundation
import SwiftUI

public protocol AuthenticateViewBuilder {
    func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView
    func loginWithEmailView() -> AnyView
    var loginWithPhoneView: AnyView { get }
    func phoneLoginCodeView(_ phoneNumber: String) -> AnyView
    func magicLinkLoginCodeView(_ code: String) -> AnyView
    func passwordRecoverView(showForgotPassword: Bool, showMagicLink: Bool) -> AnyView
    func resetPasswordView(closeAuthFlow: @escaping () -> Void, resetCode: String) -> AnyView
}

class AuthenticateComponent: Component<AppDependency> {
    internal var viewModel: AuthenticateViewModel? = nil
    internal var _loginWithEmailViewModel: LoginWithEmailViewModel? = nil
    internal var _loginWithPhoneViewModel: LoginWithPhoneViewModel? = nil
    internal var _loginWithMagicLinkViewModel: LoginWithMagicLinkViewModel? = nil
    internal var _passwordRecoverViewModel: PasswordRecoverViewModel? = nil
    internal var _resetPasswordViewModel: ResetPasswordViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let magicLinkLoginCodeId = NavigationRoute.magicLinkLoginCode("").id
        let phoneLoginCodeId = NavigationRoute.phoneLoginCode("").id
        let passwordRecoverId = NavigationRoute.recoverPassword().id
        let resetPasswordId = NavigationRoute.resetPassword("").id
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.loginWithEmail.id) {
                    self._loginWithEmailViewModel = nil
                }
                if !pathIds.contains(magicLinkLoginCodeId) {
                    self._loginWithMagicLinkViewModel = nil
                }
                if !(pathIds.contains(NavigationRoute.loginWithPhone.id) ||
                     pathIds.contains(phoneLoginCodeId)) {
                    self._loginWithPhoneViewModel = nil
                }
                if !pathIds.contains(passwordRecoverId) {
                    self._passwordRecoverViewModel = nil
                }
                if !pathIds.contains(resetPasswordId) {
                    self._resetPasswordViewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private var authenticateViewModel: AuthenticateViewModel {
        if viewModel == nil {
            viewModel = AuthenticateViewModel(
                accountDataRepository: dependency.accountDataRepository,
                accountEventBus: dependency.accountEventBus,
                incidentsRepository: dependency.incidentsRepository,
                translator: dependency.translator
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
