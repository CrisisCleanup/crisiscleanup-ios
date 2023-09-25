import SwiftUI

extension AuthenticateComponent {
    private func passwordRecoverViewModel(showForgotPassword: Bool, showMagicLink: Bool) -> PasswordRecoverViewModel {
        var isReusable = false
        if let vm = _passwordRecoverViewModel {
            isReusable = vm.showForgotPassword == showForgotPassword &&
            vm.showMagicLink == showMagicLink
        }

        if !isReusable {
            _passwordRecoverViewModel = PasswordRecoverViewModel(
                showForgotPassword: showForgotPassword,
                showMagicLink: showMagicLink
            )
        }
        return _passwordRecoverViewModel!
    }

    func passwordRecoverView(showForgotPassword: Bool, showMagicLink: Bool) -> AnyView {
        return AnyView(
            PasswordRecoverView(
                viewModel: passwordRecoverViewModel(
                    showForgotPassword: showForgotPassword,
                    showMagicLink: showMagicLink
                )
            )
        )
    }
}
