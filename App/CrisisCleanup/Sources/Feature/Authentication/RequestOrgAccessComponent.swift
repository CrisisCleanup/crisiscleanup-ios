import SwiftUI

extension VolunteerOrgComponent {
    private var requestOrgAccessViewModel: RequestOrgAccessViewModel {
        if _requestOrgAccessViewModel == nil {
            _requestOrgAccessViewModel = RequestOrgAccessViewModel(
                languageRepository: dependency.languageTranslationsRepository,
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                accountUpdateRepository: dependency.accountUpdateRepository,
                accountDataRepository: dependency.accountDataRepository,
                inputValidator: dependency.inputValidator,
                accountEventBus: dependency.accountEventBus,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                showEmailInput: true,
            )
        }
        return _requestOrgAccessViewModel!
    }

    var requestOrgAccessView: AnyView {
        AnyView(
            RequestOrgAccessView(
                viewModel: requestOrgAccessViewModel
            )
        )
    }
}
