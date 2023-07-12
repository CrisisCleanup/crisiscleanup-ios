import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseAddNoteViewBuilder {
    var caseAddNoteView: AnyView { get }
}

class CaseAddNoteComponent: Component<AppDependency>, CaseAddNoteViewBuilder {
    private var viewModel: CaseAddNoteViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseAddNote.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseAddNoteViewModel {
        if viewModel == nil {
            viewModel = CaseAddNoteViewModel(
                editableWorksiteProvider: dependency.editableWorksiteProvider
            )
        }
        return viewModel!
    }

    var caseAddNoteView: AnyView {
        AnyView(
            CaseAddNoteView(
                viewModel: getViewModel()
            )
        )
    }
}
