import SwiftUI

extension VolunteerOrgComponent {
    private var requestOrgAccessViewModel: RequestOrgAccessViewModel {
        if _requestOrgAccessViewModel == nil {
            _requestOrgAccessViewModel = RequestOrgAccessViewModel(
                languageRepository: dependency.languageTranslationsRepository,
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                inputValidator: dependency.inputValidator,
                translator: dependency.translator,
                showEmailInput: true
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
