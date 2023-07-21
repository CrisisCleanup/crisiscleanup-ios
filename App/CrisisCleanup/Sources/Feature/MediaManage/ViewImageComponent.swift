import Combine
import NeedleFoundation
import SwiftUI

public protocol ViewImageViewBuilder {
    func viewImageView(_ imageId: Int64) -> AnyView
}

class ViewImageComponent: Component<AppDependency>, ViewImageViewBuilder {
    private var viewModel: ViewImageViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let viewImagePathId = NavigationRoute.viewImage(imageId: 0).id
        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(viewImagePathId) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel(_ imageId: Int64) -> ViewImageViewModel {
        if viewModel == nil {
            viewModel = ViewImageViewModel(
                imageId: imageId
            )
        }
        return viewModel!
    }

    func viewImageView(_ imageId: Int64) -> AnyView {
        AnyView(
            ViewImageView(
                viewModel: getViewModel(imageId)
            )
            .navigationBarHidden(true)
            .statusBarHidden(true)
        )
    }
}
