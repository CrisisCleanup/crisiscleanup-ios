// sourcery: copyBuilder, skipCopyInit
public struct AppPreferences: Codable {
    let hideOnboarding: Bool
    let hideGettingStartedVideo: Bool
    let selectedIncidentId: Int64
    let languageKey: String
    let syncAttempt: SyncAttempt
    let tableViewSortBy: WorksiteSortBy
    let shareLocationWithOrg: Bool

    init(
        hideOnboarding: Bool = false,
        hideGettingStartedVideo: Bool = false,
        selectedIncidentId: Int64 = 0,
        languageKey: String = "en-US",
        syncAttempt: SyncAttempt = SyncAttempt(),
        tableViewSortBy: WorksiteSortBy = .none,
        shareLocationWithOrg: Bool = false
    ) {
        self.hideOnboarding = hideOnboarding
        self.hideGettingStartedVideo = hideGettingStartedVideo
        self.selectedIncidentId = selectedIncidentId
        self.languageKey = languageKey
        self.syncAttempt = syncAttempt
        self.tableViewSortBy = tableViewSortBy
        self.shareLocationWithOrg = shareLocationWithOrg
    }
}
