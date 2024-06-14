import Combine
import NeedleFoundation
import SwiftUI

protocol ListsViewBuilder {
    var listsView: AnyView { get }
}

class ListsComponent: Component<AppDependency>, ListsViewBuilder {
    private var _listsViewModel: ListsViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.lists.id) {
                    self._listsViewModel = nil
                }
            }
            .store(in: &disposables)
    }

    private var listsViewModel: ListsViewModel {
        if _listsViewModel == nil {
            _listsViewModel = ListsViewModel(
                incidentSelector: dependency.incidentSelector,
                listDataRefresher: dependency.listDataRefresher,
                listsRepository: dependency.listsRepository,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return _listsViewModel!
    }

    var listsView: AnyView {
        AnyView(
            ListsView(
                viewModel: listsViewModel
            )
        )
    }
}
