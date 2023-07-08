import Combine
import NeedleFoundation
import SwiftUI

public protocol CasesSearchViewBuilder {
    var casesSearchView: AnyView { get }
}

class CasesSearchComponent: Component<AppDependency>, CasesSearchViewBuilder {
    private var viewModel: CasesSearchViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.searchCases.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func casesSearchViewModel() -> CasesSearchViewModel {
        if viewModel == nil {
            viewModel = CasesSearchViewModel(
                incidentSelector: dependency.incidentSelector,
                worksitesRepository: dependency.worksitesRepository,
                searchWorksitesRepository: dependency.searchWorksitesRepository,
                mapCaseIconProvider: dependency.mapCaseIconProvider,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var casesSearchView: AnyView {
        AnyView(
            CasesSearchView(
                viewModel: casesSearchViewModel()
            )
        )
    }
}
