import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseSearchLocationViewBuilder {
    var caseSearchLocationView: AnyView { get }
}

class CaseSearchLocationComponent: Component<AppDependency>, CaseSearchLocationViewBuilder {
    private var viewModel: CaseSearchLocationViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseSearchLocation.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseSearchLocationViewModel {
        if viewModel == nil {
            viewModel = CaseSearchLocationViewModel(
            )
        }
        return viewModel!
    }

    var caseSearchLocationView: AnyView {
        AnyView(
            CaseSearchLocationView(
                viewModel: getViewModel()
            )
        )
    }
}
