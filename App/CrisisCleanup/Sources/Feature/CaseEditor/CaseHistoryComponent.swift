import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseHistoryViewBuilder {
    var caseHistoryView: AnyView { get }
}

class CaseHistoryComponent: Component<AppDependency>, CaseHistoryViewBuilder {
    private var viewModel: CaseHistoryViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseHistory.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseHistoryViewModel {
        if viewModel == nil {
            viewModel = CaseHistoryViewModel(
            )
        }
        return viewModel!
    }

    var caseHistoryView: AnyView {
        AnyView(
            CaseHistoryView(
                viewModel: getViewModel()
            )
        )
    }
}
