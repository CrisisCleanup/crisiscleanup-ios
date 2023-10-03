import Combine
import NeedleFoundation
import SwiftUI

public protocol VolunteerOrgViewBuilder {
    var volunteerOrgView: AnyView { get }
}

class VolunteerOrgComponent: Component<AppDependency>, VolunteerOrgViewBuilder {
    private var viewModel: VolunteerOrgViewModel? = nil

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
