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

    func returnToAuth() {
        clearNavigationStack()
    }

    func openEmailLogin() {
        path.append(.loginWithEmail)
    }

    func openPhoneLogin() {
        path.append(.loginWithPhone)
    }

    func openForgotPassword() {
        path.append(.recoverPassword(showForgotPassword: true, showMagicLink: true))
    }

    func openEmailMagicLink() {
        path.append(.recoverPassword(showForgotPassword: false, showMagicLink: true))
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
        popToRoot: Bool = false
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

    func returnToWork() {
        clearNavigationStack()
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

    func openCaseSearchLocation() {
        path.append(.caseSearchLocation)
    }

    func openCaseMoveOnMap() {
        path.append(.caseMoveOnMap)
    }

    func openCaseShare() {
        path.append(.caseShare)
    }
    func openCaseShareStep2() {
        path.append(.caseShareStep2)
    }
    func openCaseFlags(isFromCaseEdit: Bool) {
        path.append(.caseFlags(isFromCaseEdit))
    }
    func openCaseHistory() {
        path.append(.caseHistory)
    }
    func openWorkTypeTransfer() {
        path.append(.caseWorkTypeTransfer)
    }

    func viewImage(
        _ imageId: Int64,
        _ isNetworkImage: Bool,
        _ screenTitle: String
    ) {
        path.append(.viewImage(imageId, isNetworkImage, screenTitle))
    }

    func openUserFeedback() {
        path.append(.userFeedback)
    }

    func openSyncInsights() {
        path.append(.syncInsights)
    }
}
