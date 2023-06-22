import NeedleFoundation
import SwiftUI

protocol CasesViewBuilder {
    var casesView: AnyView { get }
}

class CasesComponent: Component<AppDependency>, CasesViewBuilder {
    var casesViewModel: CasesViewModel {
        CasesViewModel(
            incidentSelector: dependency.incidentSelector,
            loggerFactory: dependency.loggerFactory
        )
    }

    var casesView: AnyView {
        AnyView(
            CasesView(
                viewModel: casesViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder
            )
        )
    }
}
