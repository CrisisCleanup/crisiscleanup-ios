import NeedleFoundation
import SwiftUI

protocol CasesViewBuilder {
    var casesView: AnyView { get }
}

class CasesComponent: Component<AppDependency>, CasesViewBuilder {
    lazy var casesViewModel: CasesViewModel = CasesViewModel(
        incidentSelector: dependency.incidentSelector,
        incidentBoundsProvider: dependency.incidentBoundsProvider,
        incidentsRepository: dependency.incidentsRepository,
        worksitesRepository: dependency.worksitesRepository,
        accountDataRepository: dependency.accountDataRepository,
        worksiteChangeRepository: dependency.worksiteChangeRepository,
        organizationsRepository: dependency.organizationsRepository,
        appPreferences: dependency.appPreferences,
        dataPullReporter: dependency.incidentDataPullReporter,
        mapCaseIconProvider: dependency.mapCaseIconProvider,
        locationManager: dependency.locationManager,
        worksiteProvider: dependency.worksiteProvider,
        transferWorkTypeProvider: dependency.transferWorkTypeProvider,
        translator: dependency.translator,
        loggerFactory: dependency.loggerFactory
    )

    var casesView: AnyView {
        AnyView(
            CasesView(
                viewModel: casesViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder
            )
        )
    }
}
