import SwiftUI

extension VolunteerOrgComponent {
    private var requestOrgAccessViewModel: RequestOrgAccessViewModel {
        if _requestOrgAccessViewModel == nil {
            _requestOrgAccessViewModel = RequestOrgAccessViewModel(
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
