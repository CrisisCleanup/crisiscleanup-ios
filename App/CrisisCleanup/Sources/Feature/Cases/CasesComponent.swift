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
        incidentCacheRepository: dependency.incidentCacheRepository,
        accountDataRepository: dependency.accountDataRepository,
        worksiteChangeRepository: dependency.worksiteChangeRepository,
        organizationsRepository: dependency.organizationsRepository,
        appPreferences: dependency.appPreferences,
        dataPullReporter: dependency.incidentDataPullReporter,
        worksiteLocationEditor: dependency.worksiteLocationEditor,
        mapCaseIconProvider: dependency.mapCaseIconProvider,
        worksiteInteractor: dependency.worksiteInteractor,
        locationManager: dependency.locationManager,
        worksiteProvider: dependency.worksiteProvider,
        transferWorkTypeProvider: dependency.transferWorkTypeProvider,
        filterRepository: dependency.casesFilterRepository,
        phoneNumberParser: dependency.phoneNumberParser,
        translator: dependency.translator,
        syncPuller: dependency.syncPuller,
        loggerFactory: dependency.loggerFactory,
        appEnv: dependency.appEnv,
    )

    func casesView(_ openAuthScreen: @escaping () -> Void) -> AnyView {
        AnyView(
            CasesView(
                viewModel: casesViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen
            )
            .toolbar(.hidden, for: .navigationBar)
        )
    }
}
