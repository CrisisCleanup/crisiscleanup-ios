import Combine
import NeedleFoundation
import SwiftUI

public protocol CreateEditCaseViewBuilder {
    func createEditCaseView(incidentId: Int64, worksiteId: Int64?) -> AnyView
}

class CreateEditCaseComponent: Component<AppDependency>, CreateEditCaseViewBuilder {
    private var viewModel: CreateEditCaseViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let createEditCasePathId = NavigationRoute.createEditCase(incidentId: 0, worksiteId: 0).id
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(createEditCasePathId) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel(incidentId: Int64, worksiteId: Int64?) -> CreateEditCaseViewModel {
        if viewModel == nil {
            viewModel = CreateEditCaseViewModel(
                accountDataRepository: dependency.accountDataRepository,
                incidentsRepository: dependency.incidentsRepository,
                incidentRefresher: dependency.incidentRefresher,
                incidentBoundsProvider: dependency.incidentBoundsProvider,
                worksitesRepository: dependency.worksitesRepository,
                languageRepository: dependency.languageTranslationsRepository,
                languageRefresher: dependency.languageRefresher,
                workTypeStatusRepository: dependency.workTypeStatusRepository,
                editableWorksiteProvider: dependency.editableWorksiteProvider,
                locationManager: dependency.locationManager,
                networkMonitor: dependency.networkMonitor,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                syncPusher: dependency.syncPusher,
                inputValidator: dependency.inputValidator,
                translator: dependency.translator,
                appEnv: dependency.appEnv,
                loggerFactory: dependency.loggerFactory,
                incidentId: incidentId,
                worksiteId: worksiteId
            )
        }
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
