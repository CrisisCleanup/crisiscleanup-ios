import Combine
import NeedleFoundation
import SwiftUI

public protocol RequestRedeployViewBuilder {
    var requestRedeployView: AnyView { get }
}

class RequestRedeployComponent: Component<AppDependency>, RequestRedeployViewBuilder {
    private var viewModel: RequestRedeployViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.requestRedeploy.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> RequestRedeployViewModel {
        if viewModel == nil {
            viewModel = RequestRedeployViewModel(
                incidentsRepository: dependency.incidentsRepository,
                accountDataRepository: dependency.accountDataRepository,
                accountDataRefresher: dependency.accountDataRefresher,
                requestRedeployRepository: dependency.requestRedeployRepository,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var requestRedeployView: AnyView {
        AnyView(
            RequestRedeployView(
                viewModel: getViewModel()
            )
        )
    }
}
