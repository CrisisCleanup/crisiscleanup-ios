import Combine
import NeedleFoundation
import SwiftUI

public protocol VolunteerOrgViewBuilder {
    var volunteerOrgView: AnyView { get }
    var requestOrgAccessView: AnyView { get }
    func orgUserInviteView(_ code: String) -> AnyView
}

class VolunteerOrgComponent: Component<AppDependency>, VolunteerOrgViewBuilder {
    private var viewModel: VolunteerOrgViewModel? = nil
    internal var _requestOrgAccessViewModel: RequestOrgAccessViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.volunteerOrg.id) {
                    self.viewModel = nil
                }
                if !pathIds.contains(NavigationRoute.requestOrgAccess.id) {
                    self._requestOrgAccessViewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> VolunteerOrgViewModel {
        if viewModel == nil {
            viewModel = VolunteerOrgViewModel()
        }
        return viewModel!
    }

    var volunteerOrgView: AnyView {
        AnyView(
            VolunteerOrgView(
                viewModel: getViewModel()
            )
        )
    }
}
