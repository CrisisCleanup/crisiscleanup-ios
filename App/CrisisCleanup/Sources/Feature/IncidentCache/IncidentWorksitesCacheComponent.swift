import Combine
import NeedleFoundation
import SwiftUI

protocol IncidentWorksitesCacheViewBuilder {
    var incidentWorksitesCacheView: AnyView { get }
}

class IncidentWorksitesCacheComponent: Component<AppDependency>, IncidentWorksitesCacheViewBuilder {
    lazy var viewModel: IncidentWorksitesCacheViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.incidentDataCaching.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    private var incidentWorksitesCacheViewModel: IncidentWorksitesCacheViewModel {
        if viewModel == nil {
            viewModel = IncidentWorksitesCacheViewModel(
//                incidentSelector: dependency.incidentSelector,
//                syncPuller: dependency.syncPuller,
//                loggerFactory: dependency.loggerFactory,
//                appEnv: dependency.appEnv
            )
        }
        return viewModel!
    }

    var incidentWorksitesCacheView: AnyView {
        AnyView(
            IncidentWorksitesCacheView(
                viewModel: incidentWorksitesCacheViewModel
            )
        )
    }
}
