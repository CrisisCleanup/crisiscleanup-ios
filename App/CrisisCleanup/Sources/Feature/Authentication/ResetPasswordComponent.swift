import SwiftUI

extension AuthenticateComponent {
    private func resetPasswordViewModel(_ resetCode: String) -> ResetPasswordViewModel {
        if _resetPasswordViewModel == nil {
            _resetPasswordViewModel = ResetPasswordViewModel(
                resetPasswordToken: resetCode,
                accountUpdateRepository: dependency.accountUpdateRepository,
                translator: dependency.translator
            )
        }
        return _resetPasswordViewModel!
    }

    func resetPasswordView(_ resetCode: String) -> AnyView {
        return AnyView(
            ResetPasswordView(
                viewModel: resetPasswordViewModel(resetCode)
            )
        )
    }
}
