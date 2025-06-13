import Combine
import SwiftUI

class NavigationRouter: ObservableObject {
    private let routerObserver: RouterObserver

    @Published var path = [NavigationRoute]()

    private lazy var forgotPasswordPathId: Int = NavigationRoute.resetPassword("").id

    private var disposables = Set<AnyCancellable>()

    init(routerObserver: RouterObserver) {
        self.routerObserver = routerObserver

        $path.sink { navigationPath in
            routerObserver.onRouterChange(navigationPath)
        }
        .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func clearNavigationStack(_ replaceRoutes: [NavigationRoute] = []) {
        if replaceRoutes.isEmpty {
            path.removeAll()
        } else {
            path.replaceSubrange(0..<path.count, with: replaceRoutes)
        }
    }

    func clearRoutes() {
        clearNavigationStack()
    }

    func clearAuthRoutes() {
        clearNavigationStack()
    }

    func openEmailLogin(_ clearRoutes: Bool = false) {
        if clearRoutes {
            clearAuthRoutes()
        }
        path.append(.loginWithEmail)
    }

    func openPhoneLogin(_ clearRoutes: Bool = false) {
        if clearRoutes {
            clearAuthRoutes()
        }
        path.append(.loginWithPhone)
    }

    func openPhoneLoginCode(_ phoneNumber: String) {
        path.append(.phoneLoginCode(phoneNumber))
    }

    func openMagicLinkLoginCode(_ code: String) {
        path.append(.magicLinkLoginCode(code))
    }

    func openVolunteerOrg() {
        path.append(.volunteerOrg)
    }

    func openForgotPassword() {
        path.append(.recoverPassword(showForgotPassword: true, showMagicLink: true))
    }

    func openResetPassword(_ code: String) {
        let resetPasswordPath = NavigationRoute.resetPassword(code)
        let pathIds = path.map { $0.id }
        if let existingIndex = pathIds.firstIndex(of: forgotPasswordPathId) {
            let trailingIndices = existingIndex..<pathIds.count
            path.replaceSubrange(trailingIndices, with: [resetPasswordPath])
        } else {
            path.append(resetPasswordPath)
        }
    }

    func openPasteOrgInviteLink() {
        path.append(.pasteOrgInviteLink)
    }

    func openOrgUserInvite(_ code: String, popPath: Bool = false) {
        if popPath {
            _ = path.popLast()
        }

        path.append(.orgUserInvite(code))
    }

    func openOrgPersistentInvite(_ invite: UserPersistentInvite) {
        path.append(.orgPersistentInvite(invite))
    }

    func openEmailMagicLink() {
        path.append(.recoverPassword(showForgotPassword: false, showMagicLink: true))
    }

    func openRequestOrgAccess() {
        path.append(.requestOrgAccess)
    }

    func openScanOrgQrCode() {
        path.append(.scanOrgQrCode)
    }

    func openFilterCases() {
        path.append(.filterCases)
    }

    func openInviteTeammate() {
        path.append(.inviteTeammate)
    }

    func openRequesetRedeploy() {
        path.append(.requestRedeploy)
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
            let viewCasePath = NavigationRoute.viewCase(
                incidentId: incidentId,
                worksiteId: worksiteId
            )

            if popToRoot {
                clearNavigationStack([viewCasePath])
            } else {
                path.append(viewCasePath)
            }
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

    private let shareRoutes = Set<NavigationRoute>([
        .caseShare,
        .caseShareStep2
    ])
    func clearShareRoutes() {
        while path.isNotEmpty {
            if let lastPath = path.last,
               shareRoutes.contains(lastPath)
            {
                _ = path.popLast()
            } else {
                break
            }
        }
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

    func openWorksiteImages(
        worksiteId: Int64,
        imageId: Int64,
        imageUri: String,
        screenTitle: String
    ) {
        path.append(.worksiteImages(
            worksiteId: worksiteId,
            imageId: imageId,
            imageUri: imageUri,
            screenTitle: screenTitle
        ))
    }

    func openUserFeedback() {
        path.append(.userFeedback)
    }

    func openSyncInsights() {
        path.append(.syncInsights)
    }

    func changeCaseIncident(_ incidentId: Int64) {
        clearNavigationStack([
            .createEditCase(
                incidentId: incidentId,
                worksiteId: nil
            )
        ])
    }

    func changeCaseIncident(_ ids: ExistingWorksiteIdentifier) {
        viewCase(incidentId: ids.incidentId, worksiteId: ids.worksiteId, popToRoot: true)
    }

    func openLists() {
        path.append(.lists)
    }

    func viewList(_ list: CrisisCleanupList) {
        path.append(.viewList(list.id))
    }

    func openIncidentDataCaching() {
        path.append(.incidentDataCaching)
    }
}
