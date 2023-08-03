import Combine
import NeedleFoundation
import SwiftUI

public protocol CasesFilterViewBuilder {
    var casesFilterView: AnyView { get }
}

class CasesFilterComponent: Component<AppDependency>, CasesFilterViewBuilder {
    private var viewModel: CasesFilterViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.filterCases.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    private var casesFilterViewModel: CasesFilterViewModel {
        if viewModel == nil {
            viewModel =
            CasesFilterViewModel(
                workTypeStatusRepository: dependency.workTypeStatusRepository,
                casesFilterRepository: dependency.casesFilterRepository,
                incidentSelector: dependency.incidentSelector,
                incidentsRepository: dependency.incidentsRepository,
                languageRepository: dependency.languageTranslationsRepository,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var casesFilterView: AnyView {
        AnyView(
            CasesFilterView(
                viewModel: casesFilterViewModel
            )
        )
    }
}
