import NeedleFoundation
import SwiftUI

public protocol AuthenticateViewBuilder {
    func authenticateView(dismissScreen: @escaping () -> Void) -> AnyView
}

class AuthenticateComponent: Component<AppDependency> {
    private var viewModel: AuthenticateViewModel? = nil

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
