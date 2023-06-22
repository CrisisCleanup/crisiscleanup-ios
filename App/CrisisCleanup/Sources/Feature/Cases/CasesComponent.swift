import NeedleFoundation
import SwiftUI

protocol CasesViewBuilder {
    var casesView: AnyView { get }
}

class CasesComponent: Component<AppDependency>, CasesViewBuilder {
    var casesViewModel: CasesViewModel {
        CasesViewModel(
            appEnv: dependency.appEnv,
            accountDataRepository: dependency.accountDataRepository,
            incidentSelector: dependency.incidentSelector,
            appVersionProvider: dependency.appVersionProvider,
            authEventBus: dependency.authEventBus,
            loggerFactory: dependency.loggerFactory
        )
    }

    var casesView: AnyView {
        AnyView(
            CasesView(
                viewModel: casesViewModel,
                authenticateViewBuilder: dependency.authenticateViewBuilder,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder
            )
        )
    }
}
