import SwiftUI

extension AuthenticateComponent {
    private func loginWithPhoneViewModel(_ phoneNumber: String = "") -> LoginWithPhoneViewModel {
        var isReusable = false
        if let vm = _loginWithPhoneViewModel {
            isReusable = vm.phoneNumber == phoneNumber
        }

        if !isReusable {
            _loginWithPhoneViewModel = LoginWithPhoneViewModel(
                authApi: dependency.authApi,
                dataApi: dependency.networkDataSource,
                accountUpdateRepository: dependency.accountUpdateRepository,
                accountDataRepository: dependency.accountDataRepository,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                phoneNumber: phoneNumber
            )
        }
        return _loginWithPhoneViewModel!
    }

    var loginWithPhoneView: AnyView {
        AnyView(
            LoginWithPhoneView(
                viewModel: loginWithPhoneViewModel()
            )
        )
    }

    func phoneLoginCodeView(_ phoneNumber: String, closeAuthFlow: @escaping () -> Void) -> AnyView {
        let clearViewModelOnHide = {
            self._loginWithPhoneViewModel = nil
            closeAuthFlow()
        }
        return AnyView(
            LoginPhoneCodeView(
                viewModel: loginWithPhoneViewModel(phoneNumber),
                dismiss: clearViewModelOnHide
            )
        )
    }
}
