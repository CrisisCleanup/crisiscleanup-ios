import SwiftUI

extension VolunteerOrgComponent {
    private func orgUserInviteViewModel(_ code: String) -> RequestOrgAccessViewModel {
        var isReusable = false
        if let vm = _requestOrgAccessViewModel {
            isReusable = vm.showEmailInput == false &&
            vm.invitationCode == code &&
            vm.invitingUserId == 0
        }

        if  !isReusable {
            _requestOrgAccessViewModel = RequestOrgAccessViewModel(
                languageRepository: dependency.languageTranslationsRepository,
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                inputValidator: dependency.inputValidator,
                translator: dependency.translator,
                invitationCode: code
            )
        }
        return _requestOrgAccessViewModel!
    }

    func orgUserInviteView(_ code: String) -> AnyView {
        AnyView(
            RequestOrgAccessView(
                viewModel: orgUserInviteViewModel(code)
            )
        )
    }
}
