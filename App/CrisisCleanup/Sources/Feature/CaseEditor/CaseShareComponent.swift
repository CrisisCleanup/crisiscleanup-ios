import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseShareViewBuilder {
    var caseShareView: AnyView { get }
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
}
