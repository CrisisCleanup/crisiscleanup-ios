import Combine
import NeedleFoundation
import SwiftUI

public protocol ViewImageViewBuilder {
    func viewImageView(
        _ imageId: Int64,
        _ isNetworkImage: Bool,
        _ screenTitle: String
    ) -> AnyView
}

class ViewImageComponent: Component<AppDependency>, ViewImageViewBuilder {
    private var viewModel: ViewImageViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        let viewImagePathId = NavigationRoute.viewImage(0, false, "").id
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

    private func getViewModel(
        _ imageId: Int64,
        _ isNetworkImage: Bool,
        _ screenTitle: String
    ) -> ViewImageViewModel {
        if viewModel == nil {
            viewModel = ViewImageViewModel(
                localImageRepository: dependency.localImageRepository,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                translator: dependency.translator,
                accountDataRepository: dependency.accountDataRepository,
                syncPusher: dependency.syncPusher,
                networkMonitor: dependency.networkMonitor,
                loggerFactory: dependency.loggerFactory,
                imageId: imageId,
                isNetworkImage: isNetworkImage,
                screenTitle: screenTitle
            )
        }
        return viewModel!
    }

    func viewImageView(
        _ imageId: Int64,
        _ isNetworkImage: Bool,
        _ screenTitle: String
    ) -> AnyView {
        AnyView(
            ViewImageView(
                viewModel: getViewModel(imageId, isNetworkImage, screenTitle)
            )
            .navigationBarHidden(true)
            .statusBarHidden(true)
        )
    }
}
