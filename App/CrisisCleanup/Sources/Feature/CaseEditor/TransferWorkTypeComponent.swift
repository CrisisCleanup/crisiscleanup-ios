import Combine
import NeedleFoundation
import SwiftUI

public protocol TransferWorkTypeViewBuilder {
    var transferWorkTypeView: AnyView { get }
}

class TransferWorkTypeComponent: Component<AppDependency>, TransferWorkTypeViewBuilder {
    private var viewModel: TransferWorkTypeViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver,
        transferWorkTypeProvider: TransferWorkTypeProvider
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseWorkTypeTransfer.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> TransferWorkTypeViewModel {
        if viewModel == nil {
            viewModel = TransferWorkTypeViewModel(
            )
        }
        return viewModel!
    }

    var transferWorkTypeView: AnyView {
        AnyView(
            TransferWorkTypeView(
                viewModel: getViewModel()
            )
        )
    }
}
