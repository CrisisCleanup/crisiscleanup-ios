import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseMoveOnMapViewBuilder {
    var caseMoveOnMapView: AnyView { get }
}

class CaseMoveOnMapComponent: Component<AppDependency>, CaseMoveOnMapViewBuilder {
    private var viewModel: CaseMoveOnMapViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseMoveOnMap.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseMoveOnMapViewModel {
        if viewModel == nil {
            viewModel = CaseMoveOnMapViewModel(
            )
        }
        return viewModel!
    }

    var caseMoveOnMapView: AnyView {
        AnyView(
            CaseMoveOnMapView(
                viewModel: getViewModel()
            )
        )
    }
}
