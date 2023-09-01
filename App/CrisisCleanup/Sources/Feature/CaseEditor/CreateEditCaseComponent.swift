import Combine
import NeedleFoundation
import SwiftUI

public protocol CreateEditCaseViewBuilder {
    func createEditCaseView(incidentId: Int64, worksiteId: Int64?) -> AnyView
}

class CreateEditCaseComponent: Component<AppDependency>, CreateEditCaseViewBuilder {
    private let routerObserver: RouterObserver
    private let pathId: Int

    private var viewModel: CreateEditCaseViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        self.routerObserver = routerObserver
        pathId = NavigationRoute.createEditCase(incidentId: 0, worksiteId: 0).id

        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(self.pathId) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel(incidentId: Int64, worksiteId: Int64?) -> CreateEditCaseViewModel {
        let isRelevant = routerObserver.isInPath(pathId)
        if isRelevant,
           let existingViewModel = viewModel,
           existingViewModel.incidentIdIn == incidentId,
           existingViewModel.worksiteIdLatest == worksiteId {
            return existingViewModel
        }

        viewModel = CreateEditCaseViewModel(
            accountDataRepository: dependency.accountDataRepository,
            incidentsRepository: dependency.incidentsRepository,
            incidentRefresher: dependency.incidentRefresher,
            incidentBoundsProvider: dependency.incidentBoundsProvider,
            worksitesRepository: dependency.worksitesRepository,
            languageRepository: dependency.languageTranslationsRepository,
            languageRefresher: dependency.languageRefresher,
            workTypeStatusRepository: dependency.workTypeStatusRepository,
            worksiteProvider: dependency.editableWorksiteProvider,
            locationManager: dependency.locationManager,
            addressSearchRepository: dependency.addressSearchRepository,
            caseIconProvider: dependency.mapCaseIconProvider,
            networkMonitor: dependency.networkMonitor,
            searchWorksitesRepository: dependency.searchWorksitesRepository,
            mapCaseIconProvider: dependency.mapCaseIconProvider,
            existingWorksiteSelector: dependency.existingWorksiteSelector,
            incidentSelector: dependency.incidentSelector,
            worksiteChangeRepository: dependency.worksiteChangeRepository,
            syncPusher: dependency.syncPusher,
            inputValidator: dependency.inputValidator,
            translator: dependency.translator,
            appEnv: dependency.appEnv,
            loggerFactory: dependency.loggerFactory,
            incidentId: incidentId,
            worksiteId: worksiteId
        )
        return viewModel!
    }

    func createEditCaseView(incidentId: Int64, worksiteId: Int64?) -> AnyView {
        AnyView(
            CreateEditCaseView(
                viewModel: getViewModel(
                    incidentId: incidentId,
                    worksiteId: worksiteId
                )
            )
        )
    }
}
