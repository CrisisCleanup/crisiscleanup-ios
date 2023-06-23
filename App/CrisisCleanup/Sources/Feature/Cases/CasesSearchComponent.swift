import NeedleFoundation
import SwiftUI

public protocol CasesSearchViewBuilder {
    var casesSearchView: AnyView { get }
}

class CasesSearchComponent: Component<AppDependency>, CasesSearchViewBuilder {
    var casesSearchViewModel: CasesSearchViewModel {
        CasesSearchViewModel(
            incidentSelector: dependency.incidentSelector,
            worksitesRepository: dependency.worksitesRepository,
            searchWorksitesRepository: dependency.searchWorksitesRepository,
            mapCaseIconProvider: dependency.mapCaseIconProvider,
            loggerFactory: dependency.loggerFactory
        )
    }

    var casesSearchView: AnyView {
        AnyView(
            CasesSearchView(
                viewModel: casesSearchViewModel
            )
        )
    }
}
