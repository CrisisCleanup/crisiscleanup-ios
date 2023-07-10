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
