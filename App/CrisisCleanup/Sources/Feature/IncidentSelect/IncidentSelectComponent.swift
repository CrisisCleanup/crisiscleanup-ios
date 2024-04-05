import NeedleFoundation
import SwiftUI

public protocol IncidentSelectViewBuilder {
    func incidentSelectView(onDismiss: @escaping () -> Void) -> AnyView
    func onIncidentSelectDismiss()
}

class IncidentSelectComponent: Component<AppDependency>, IncidentSelectViewBuilder {
    private var viewModel: IncidentSelectViewModel? = nil

    private func getViewModel() -> IncidentSelectViewModel {
        if viewModel == nil {
            viewModel = IncidentSelectViewModel(
                incidentSelector: dependency.incidentSelector,
                syncPuller: dependency.syncPuller
            )
        }
        return viewModel!
    }

    func incidentSelectView(onDismiss: @escaping () -> Void) -> AnyView {
        AnyView(
            IncidentSelectView(
                viewModel: getViewModel(),
                onDismiss: onDismiss
            )
        )
    }

    func onIncidentSelectDismiss() {
        viewModel = nil
    }
}
