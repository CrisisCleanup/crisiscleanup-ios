import Combine
import NeedleFoundation
import SwiftUI

public protocol ViewCaseViewBuilder {
    func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView
}

class ViewCaseComponent: Component<AppDependency>, ViewCaseViewBuilder {
    private var viewModel: ViewCaseViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let viewCasePathId = NavigationRoute.viewCase(incidentId: 0, worksiteId: 0).id
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(viewCasePathId) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel(incidentId: Int64, worksiteId: Int64) -> ViewCaseViewModel {
        if viewModel == nil {
            viewModel = ViewCaseViewModel(
                accountDataRepository: dependency.accountDataRepository,
                incidentsRepository: dependency.incidentsRepository,
                organizationsRepository: dependency.organizationsRepository,
                accountDataRefresher: dependency.accountDataRefresher,
                incidentRefresher: dependency.incidentRefresher,
                incidentBoundsProvider: dependency.incidentBoundsProvider,
                locationManager: dependency.locationManager,
                worksitesRepository: dependency.worksitesRepository,
                languageRepository: dependency.languageTranslationsRepository,
                languageRefresher: dependency.languageRefresher,
                workTypeStatusRepository: dependency.workTypeStatusRepository,
                editableWorksiteProvider: dependency.editableWorksiteProvider,
                transferWorkTypeProvider: dependency.transferWorkTypeProvider,
                localImageRepository: dependency.localImageRepository,
                translator: dependency.translator,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                syncPusher: dependency.syncPusher,
                appEnv: dependency.appEnv,
                loggerFactory: dependency.loggerFactory,
                incidentId: incidentId,
                worksiteId: worksiteId
            )
        }
        return viewModel!
    }

    func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView {
        AnyView(
            ViewCaseView(
                viewModel: getViewModel(
                    incidentId: incidentId,
                    worksiteId: worksiteId
                )
            )
        )
    }
}
