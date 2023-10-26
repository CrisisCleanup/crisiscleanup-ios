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

    private func persistentInviteViewModel(_ token: String) -> PersistentInviteViewModel {
        var isReusable = false
        if let vm = _persistentInviteViewModel {
            isReusable = vm.inviteToken == token
        }

        if  !isReusable {
            _persistentInviteViewModel = PersistentInviteViewModel(
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                inputValidator: dependency.inputValidator,
                translator: dependency.translator,
                inviteToken: token
            )
        }
        return _persistentInviteViewModel!
    }

    func orgPersistentInviteView(_ token: String) -> AnyView {
        AnyView(
            PersistentInviteView(
                viewModel: persistentInviteViewModel(token)
            )
        )
    }
}
