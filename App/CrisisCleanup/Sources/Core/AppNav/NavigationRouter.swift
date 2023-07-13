import Combine
import SwiftUI

class NavigationRouter: ObservableObject {
    private let routerObserver: RouterObserver

    @Published var path = [NavigationRoute]()

    private var disposables = Set<AnyCancellable>()

    init(routerObserver: RouterObserver) {
        self.routerObserver = routerObserver

        $path.sink { navigationPath in
            routerObserver.onRouterChange(navigationPath)
        }
        .store(in: &disposables)
    }

    private func clearNavigationStack() {
        path.removeAll()
    }

    func openAuthentication() {
        path.append(.authenticate)
    }

    func openFilterCases() {
        path.append(.filterCases)
    }

    func openSearchCases() {
        path.append(.searchCases)
    }

    func viewCase(
        incidentId: Int64,
        worksiteId: Int64,
        popToRoot: Bool = true
    ) {
        if incidentId > 0 && worksiteId > 0 {
            if popToRoot {
                clearNavigationStack()
            }

            path.append(.viewCase(
                incidentId: incidentId,
                worksiteId: worksiteId
            ))
        }
    }

    func openCaseAddNote() {
        path.append(.caseAddNote)
    }

    func createEditCase(
        incidentId: Int64,
        worksiteId: Int64?
    ) {
        path.append(.createEditCase(
            incidentId: incidentId,
            worksiteId: worksiteId
        ))
    }

    func openCaseShare() {
        path.append(.caseShare)
    }
    func openCaseFlags() {
        path.append(.caseFlags)
    }
    func openCaseHistory() {
        path.append(.caseHistory)
    }
    func openWorkTypeTransfer() {
        path.append(.caseWorkTypeTransfer)
    }

    func viewImage(
        imageId: Int64
    ) {
        path.append(.viewImage(imageId: imageId))
    }
}
