import NeedleFoundation
import SwiftUI

public protocol ViewCaseViewBuilder {
    func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView
    func onViewCasePopped(incidentId: Int64, worksiteId: Int64)
}

class ViewCaseComponent: Component<AppDependency>, ViewCaseViewBuilder {
    private var viewCaseViewModel: ViewCaseViewModel? = nil

    func viewCaseViewModel(incidentId: Int64, worksiteId: Int64) -> ViewCaseViewModel {
        if  viewCaseViewModel?.isReusable(
            incidentId: incidentId,
            worksiteId: worksiteId
        ) != true {
            viewCaseViewModel = ViewCaseViewModel(
                incidentsRepository: dependency.incidentsRepository,
                worksitesRepository: dependency.worksitesRepository,
                loggerFactory: dependency.loggerFactory,
                incidentId: incidentId,
                worksiteId: worksiteId
            )
        }
        return viewCaseViewModel!
    }

    func onViewCasePopped(incidentId: Int64, worksiteId: Int64) {
        viewCaseViewModel?.onViewPop(incidentId: incidentId, worksiteId: worksiteId)
    }

    func viewCaseView(incidentId: Int64, worksiteId: Int64) -> AnyView {
        AnyView(
            ViewCaseView(
                viewModel: viewCaseViewModel(
                    incidentId: incidentId,
                    worksiteId: worksiteId
                )
            )
        )
    }
}
