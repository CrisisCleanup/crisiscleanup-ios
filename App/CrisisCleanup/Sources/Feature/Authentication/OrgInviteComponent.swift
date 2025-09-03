import SwiftUI

extension VolunteerOrgComponent {
    private func orgUserInviteViewModel(_ code: String) -> RequestOrgAccessViewModel {
        var isReusable = false
        if let vm = _requestOrgAccessViewModel {
            isReusable = vm.showEmailInput == false &&
            vm.invitationCode == code
        }

        if  !isReusable {
            _requestOrgAccessViewModel = RequestOrgAccessViewModel(
                languageRepository: dependency.languageTranslationsRepository,
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                accountUpdateRepository: dependency.accountUpdateRepository,
                accountDataRepository: dependency.accountDataRepository,
                inputValidator: dependency.inputValidator,
                accountEventBus: dependency.accountEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                invitationCode: code,
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

    private func persistentInviteViewModel(_ invite: UserPersistentInvite) -> PersistentInviteViewModel {
        var isReusable = false
        if let vm = _persistentInviteViewModel {
            isReusable = vm.invite == invite
        }

        if  !isReusable {
            _persistentInviteViewModel = PersistentInviteViewModel(
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                languageRepository: dependency.languageTranslationsRepository,
                inputValidator: dependency.inputValidator,
                translator: dependency.translator,
                invite: invite
            )
        }
        return _persistentInviteViewModel!
    }

    func orgPersistentInviteView(_ invite: UserPersistentInvite) -> AnyView {
        AnyView(
            PersistentInviteView(
                viewModel: persistentInviteViewModel(invite)
            )
        )
    }

    private var pasteOrgInviteViewModel: PasteOrgInviteViewModel {
        if _pasteOrgInviteViewModel == nil {
            _pasteOrgInviteViewModel = PasteOrgInviteViewModel(
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                translator: dependency.translator
            )
        }
        return _pasteOrgInviteViewModel!
    }

    var pasteOrgInviteView: AnyView {
        AnyView(
            PasteOrgInviteView(
                viewModel: pasteOrgInviteViewModel
            )
        )
    }

    private var scanQrCodeJoinOrgViewModel: ScanQrCodeJoinOrgViewModel {
        if _scanQrCodeJoinOrgViewModel == nil {
            _scanQrCodeJoinOrgViewModel = ScanQrCodeJoinOrgViewModel(
                externalEventBus: dependency.externalEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return _scanQrCodeJoinOrgViewModel!
    }

    var scanQrCodeJoinOrgView: AnyView {
        AnyView(
            ScanQrCodeJoinOrgView(
                viewModel: scanQrCodeJoinOrgViewModel
            )
        )
    }
}
