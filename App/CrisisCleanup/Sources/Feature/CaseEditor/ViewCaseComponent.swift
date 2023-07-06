import NeedleFoundation
import SwiftUI

public protocol ViewCaseViewBuilder {
    func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView
}

class ViewCaseComponent: Component<AppDependency>, ViewCaseViewBuilder {
    private var viewCaseViewModel: ViewCaseViewModel? = nil

    func viewCaseViewModel(incidentId: Int64, worksiteId: Int64) -> ViewCaseViewModel {
        ViewCaseViewModel(
            accountDataRepository: dependency.accountDataRepository,
            incidentsRepository: dependency.incidentsRepository,
            organizationsRepository: dependency.organizationsRepository,
            incidentRefresher: IncidentRefresher(
                dependency.incidentsRepository,
                dependency.networkMonitor,
                dependency.loggerFactory
            ),
            incidentBoundsProvider: dependency.incidentBoundsProvider,
            worksitesRepository: dependency.worksitesRepository,
            languageRepository: dependency.languageTranslationsRepository,
            languageRefresher: LanguageRefresher(
                dependency.languageTranslationsRepository,
                dependency.networkMonitor,
                dependency.loggerFactory
            ),
            workTypeStatusRepository: dependency.workTypeStatusRepository,
            editableWorksiteProvider: dependency.editableWorksiteProvider,
            translator: dependency.translator,
            worksiteChangeRepository: dependency.worksiteChangeRepository,
            syncPusher: dependency.syncPusher,
            networkMonitor: dependency.networkMonitor,
            appEnv: dependency.appEnv,
            loggerFactory: dependency.loggerFactory,
            incidentId: incidentId,
            worksiteId: worksiteId
        )
    }

    func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView {
        AnyView(
            ViewCaseView(
                viewModel: viewCaseViewModel(
                    incidentId: incidentId,
                    worksiteId: worksiteId
                )
            )
        )
    }
}
