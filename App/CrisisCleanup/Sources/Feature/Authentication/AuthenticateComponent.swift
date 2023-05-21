import NeedleFoundation
import SwiftUI

class AuthenticateComponent: Component<AppDependency> {
    var authenticateViewModel: AuthenticateViewModel {
        AuthenticateViewModel(
            appEnv: dependency.appEnv,
            loggerFactory: dependency.loggerFactory
        )
    }

    var authenticateView: some View {
        AuthenticateView(
            viewModel: authenticateViewModel
        )
    }
}
