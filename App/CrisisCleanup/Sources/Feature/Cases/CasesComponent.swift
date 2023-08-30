import NeedleFoundation
import SwiftUI

protocol CasesViewBuilder {
    func casesView(_ openAuthScreen: @escaping () -> Void) -> AnyView
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
        worksiteLocationEditor: dependency.worksiteLocationEditor,
        mapCaseIconProvider: dependency.mapCaseIconProvider,
        locationManager: dependency.locationManager,
        worksiteProvider: dependency.worksiteProvider,
        transferWorkTypeProvider: dependency.transferWorkTypeProvider,
        filterRepository: dependency.casesFilterRepository,
        translator: dependency.translator,
        syncPuller: dependency.syncPuller,
        loggerFactory: dependency.loggerFactory,
        appEnv: dependency.appEnv
    )

    func casesView(_ openAuthScreen: @escaping () -> Void) -> AnyView {
        AnyView(
            CasesView(
                viewModel: casesViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen
            )
        )
    }
}
