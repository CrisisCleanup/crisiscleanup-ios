import SwiftUI

class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()

    func openAuthentication() {
        path.append(NavigationRoute.authenticate)
    }

    func openFilterCases() {
        path.append(NavigationRoute.filterCases)
    }

    func openSearchCases() {
        path.append(NavigationRoute.searchCases)
    }

    func viewCase(incidentId: Int64, worksiteId: Int64) {
        if incidentId > 0 && worksiteId > 0 {
            path.append(NavigationRoute.viewCase(
                incidentId: incidentId,
                worksiteId: worksiteId
            ))
        }
    }
}
