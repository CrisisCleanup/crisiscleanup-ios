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
                accountEventBus: dependency.accountEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                appEnv: dependency.appEnv,
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

    func phoneLoginCodeView(_ phoneNumber: String) -> AnyView {
        AnyView(
            LoginPhoneCodeView(
                viewModel: loginWithPhoneViewModel(phoneNumber)
            )
        )
    }
}
