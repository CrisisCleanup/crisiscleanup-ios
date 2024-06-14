import Combine
import NeedleFoundation
import SwiftUI

protocol ListsViewBuilder {
    var listsView: AnyView { get }
    func viewListView(_ listId: Int64) -> AnyView
}

class ListsComponent: Component<AppDependency>, ListsViewBuilder {
    private var _listsViewModel: ListsViewModel? = nil
    private var _viewListViewModel: ViewListViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let viewListId = NavigationRoute.viewList(0).id
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.lists.id) {
                    self._listsViewModel = nil
                }
                if !pathIds.contains(viewListId) {
                    self._viewListViewModel = nil
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

    private func viewListViewModel(_ listId: Int64) -> ViewListViewModel {
        let isDifferentList = _viewListViewModel?.listId != listId
        if isDifferentList {
            _viewListViewModel = ViewListViewModel(
                listsRepository: dependency.listsRepository,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                listId: listId
            )
        }
        return _viewListViewModel!
    }

    func viewListView(_ listId: Int64) -> AnyView {
        AnyView(
            ViewListView(
                viewModel: viewListViewModel(listId)
            )
            .id("view-list-\(listId)")
        )
    }
}
