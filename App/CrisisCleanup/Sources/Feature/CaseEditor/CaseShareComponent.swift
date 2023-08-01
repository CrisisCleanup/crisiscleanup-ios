import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseShareViewBuilder {
    var caseShareView: AnyView { get }
    var caseShareStep2View: AnyView { get }
}

class CaseShareComponent: Component<AppDependency>, CaseShareViewBuilder {
    private var viewModel: CaseShareViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseShare.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseShareViewModel {
        if viewModel == nil {
            viewModel = CaseShareViewModel(
                editableWorksiteProvider: dependency.editableWorksiteProvider,
                usersRepository: dependency.usersRepository,
                organizationsRepository: dependency.organizationsRepository,
                accountDataRepository: dependency.accountDataRepository,
                worksitesRepository: dependency.worksitesRepository,
                networkMonitor: dependency.networkMonitor,
                inputValidator: dependency.inputValidator,
                translator: dependency.translator
            )
        }
        return viewModel!
    }

    var caseShareView: AnyView {
        AnyView(
            CaseShareView(
                viewModel: getViewModel()
            )
        )
    }

    var caseShareStep2View: AnyView {
        AnyView(
            CaseShareStep2View(
                viewModel: getViewModel()
            )
        )
    }
}
