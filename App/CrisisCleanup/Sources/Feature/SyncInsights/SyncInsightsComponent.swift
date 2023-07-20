import Combine
import NeedleFoundation
import SwiftUI

public protocol SyncInsightsViewBuilder {
    var syncInsightsView: AnyView { get }
}

class SyncInsightsComponent: Component<AppDependency>, SyncInsightsViewBuilder {
    private var viewModel: SyncInsightsViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.syncInsights.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> SyncInsightsViewModel {
        if viewModel == nil {
            viewModel = SyncInsightsViewModel(
                syncLogRepository: dependency.syncLogRepository,
                worksitesRepository: dependency.worksitesRepository,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                syncPusher: dependency.syncPusher,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var syncInsightsView: AnyView {
        AnyView(
            SyncInsightsView(
                viewModel: getViewModel()
            )
        )
    }
}
