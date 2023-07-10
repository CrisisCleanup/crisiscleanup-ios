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
        path.append(NavigationRoute.authenticate)
    }

    func openFilterCases() {
        path.append(NavigationRoute.filterCases)
    }

    func openSearchCases() {
        path.append(NavigationRoute.searchCases)
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

            path.append(NavigationRoute.viewCase(
                incidentId: incidentId,
                worksiteId: worksiteId
            ))
        }
    }

    func openCaseShare() {
        print("Open case share")
    }
    func openCaseFlags() {
        print("Open case flags")
    }
    func openCaseHistory() {
        print("Open case history")
    }
    func openWorkTypeTransfer() {
        print("Transfer work type")
    }
}
