import NeedleFoundation
import SwiftUI

public protocol CasesFilterViewBuilder {
    var casesFilterView: AnyView { get }
}

class CasesFilterComponent: Component<AppDependency>, CasesFilterViewBuilder {
    private lazy var casesFilterViewModel: CasesFilterViewModel = {
        CasesFilterViewModel(
            loggerFactory: dependency.loggerFactory
        )
    }()

    var casesFilterView: AnyView {
        AnyView(
            CasesFilterView(
                viewModel: casesFilterViewModel
            )
        )
    }
}
