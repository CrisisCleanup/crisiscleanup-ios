import Combine
import NeedleFoundation
import SwiftUI

protocol UserFeedbackViewBuilder {
    var userFeedbackView: AnyView { get }
}

class UserFeedbackComponent: Component<AppDependency>, UserFeedbackViewBuilder {
    private var viewModel: UserFeedbackViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.userFeedback.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    private var userFeedbackViewModel: UserFeedbackViewModel {
        if viewModel == nil {
            viewModel =
            UserFeedbackViewModel(
                accountDataRepository: dependency.accountDataRepository
            )
        }
        return viewModel!
    }

    var userFeedbackView: AnyView {
        AnyView(
            UserFeedbackView(
                viewModel: userFeedbackViewModel
            )
        )
    }
}
