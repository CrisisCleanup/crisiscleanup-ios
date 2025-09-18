import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseFlagsViewBuilder {
    func caseFlagsView(isFromCaseEdit: Bool) -> AnyView
}

class CaseFlagsComponent: Component<AppDependency>, CaseFlagsViewBuilder {
    private var viewModel: CaseFlagsViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let flagPath = NavigationRoute.caseFlags(false)
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(flagPath.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel(_ isFromCaseEdit: Bool) -> CaseFlagsViewModel {
        if viewModel == nil {
            viewModel = CaseFlagsViewModel(
                isFromCaseEdit: isFromCaseEdit,
                worksiteProvider: dependency.worksiteProvider,
                editableWorksiteProvider: dependency.editableWorksiteProvider,
                organizationsRepository: dependency.organizationsRepository,
                incidentsRepository: dependency.incidentsRepository,
                accountDataRepository: dependency.accountDataRepository,
                addressSearchRepository: dependency.addressSearchRepository,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                appDataManagementRepository: dependency.appDataManagementRepository,
                incidentSelectManager: dependency.incidentSelector,
                syncPusher: dependency.syncPusher,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    func caseFlagsView(isFromCaseEdit: Bool) -> AnyView {
        AnyView(
            CaseFlagsView(
                viewModel: getViewModel(isFromCaseEdit)
            )
        )
    }
}
