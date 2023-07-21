import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseFlagsViewBuilder {
    var caseFlagsView: AnyView { get }
}

class CaseFlagsComponent: Component<AppDependency>, CaseFlagsViewBuilder {
    private var viewModel: CaseFlagsViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseFlags.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseFlagsViewModel {
        if viewModel == nil {
            viewModel = CaseFlagsViewModel(
                editableWorksiteProvider: dependency.editableWorksiteProvider,
                organizationsRepository: dependency.organizationsRepository,
                incidentsRepository: dependency.incidentsRepository,
                databaseManagementRepository: dependency.databaseManagementRepository,
                accountDataRepository: dependency.accountDataRepository,
                addressSearchRepository: dependency.addressSearchRepository,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                incidentSelectManager: dependency.incidentSelector,
                syncPusher: dependency.syncPusher,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var caseFlagsView: AnyView {
        AnyView(
            CaseFlagsView(
                viewModel: getViewModel()
            )
        )
    }
}
