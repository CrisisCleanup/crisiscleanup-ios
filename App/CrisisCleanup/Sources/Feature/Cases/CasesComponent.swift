import NeedleFoundation
import SwiftUI

protocol CasesViewBuilder {
    var casesView: AnyView { get }
}

class CasesComponent: Component<AppDependency>, CasesViewBuilder {
    lazy var casesViewModel: CasesViewModel = {
        CasesViewModel(
            incidentSelector: dependency.incidentSelector,
            incidentBoundsProvider: dependency.incidentBoundsProvider,
            incidentsRepository: dependency.incidentsRepository,
            worksitesRepository: dependency.worksitesRepository,
            dataPullReporter: dependency.incidentDataPullReporter,
            mapCaseIconProvider: dependency.mapCaseIconProvider,
            loggerFactory: dependency.loggerFactory
        )
    }()

    var casesView: AnyView {
        AnyView(
            CasesView(
                viewModel: casesViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder,
                casesSearchViewBuilder: dependency.casesSearchViewBuilder
            )
        )
    }
}
