import Combine
import NeedleFoundation
import SwiftUI

public protocol WorksiteImagesViewBuilder {
    func worksiteImagesView(
        worksiteId: Int64,
        imageId: Int64,
        imageUri: String,
        screenTitle: String
    ) -> AnyView
}

class WorksiteImagesComponent: Component<AppDependency>, WorksiteImagesViewBuilder {
    private var viewModel: WorksiteImagesViewModel? = nil

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
        _ worksiteId: Int64,
        _ imageId: Int64,
        _ imageUri: String,
        _ screenTitle: String
    ) -> WorksiteImagesViewModel {
        if viewModel == nil {
            viewModel = WorksiteImagesViewModel(
                worksiteImageRepository: dependency.worksiteImageRepository,
                localImageRepository: dependency.localImageRepository,
                worksiteChangeRepository: dependency.worksiteChangeRepository,
                accountDataRepository: dependency.accountDataRepository,
                syncPusher: dependency.syncPusher,
                networkMonitor: dependency.networkMonitor,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory,
                worksiteId: worksiteId,
                imageId: imageId,
                imageUri: imageUri,
                screenTitle: screenTitle
            )
        }
        return viewModel!
    }

    func worksiteImagesView(
        worksiteId: Int64,
        imageId: Int64,
        imageUri: String,
        screenTitle: String
    ) -> AnyView {
        let viewId = "worksite-images-\(worksiteId)"
        return AnyView(
            WorksiteImagesView(
                viewModel: getViewModel(worksiteId, imageId, imageUri, screenTitle)
            )
            .id(viewId)
            .toolbar(.hidden, for: .navigationBar)
        )
    }
}
