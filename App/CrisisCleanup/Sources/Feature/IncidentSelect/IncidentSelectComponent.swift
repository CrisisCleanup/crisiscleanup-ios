import NeedleFoundation
import SwiftUI

public protocol IncidentSelectViewBuilder {
    func incidentSelectView(onDismiss: @escaping () -> Void) -> AnyView
}

class IncidentSelectComponent: Component<AppDependency>, IncidentSelectViewBuilder {
    var incidentSelectViewModel: IncidentSelectViewModel {
        IncidentSelectViewModel(
            incidentSelector: dependency.incidentSelector
        )
    }

    func incidentSelectView(onDismiss: @escaping () -> Void) -> AnyView {
        AnyView(
            IncidentSelectView(
                viewModel: incidentSelectViewModel,
                onDismiss: onDismiss
            )
        )
    }
}
