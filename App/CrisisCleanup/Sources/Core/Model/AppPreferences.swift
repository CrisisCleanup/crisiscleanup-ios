// sourcery: copyBuilder, skipCopyInit
public struct AppPreferences: Codable {
    let hideOnboarding: Bool
    let hideGettingStartedVideo: Bool
    let selectedIncidentId: Int64
    let languageKey: String
    let syncAttempt: SyncAttempt?
    let tableViewSortBy: WorksiteSortBy
    let shareLocationWithOrg: Bool
    let notifyDataSyncProgress: Bool?

    let casesMapBounds: IncidentCoordinateBounds?
    let teamMapBounds: IncidentCoordinateBounds?

    let isWorkScreenTableView: Bool?

    init(
        hideOnboarding: Bool = false,
        hideGettingStartedVideo: Bool = false,
        selectedIncidentId: Int64 = EmptyIncident.id,
        languageKey: String = "en-US",
        syncAttempt: SyncAttempt? = nil,
        tableViewSortBy: WorksiteSortBy = .none,
        shareLocationWithOrg: Bool = false,
        notifyDataSyncProgress: Bool? = false,
        casesMapBounds: IncidentCoordinateBounds? = IncidentCoordinateBoundsNone,
        teamMapBounds: IncidentCoordinateBounds? = IncidentCoordinateBoundsNone,
        isWorkScreenTableView: Bool? = false,
    ) {
        self.hideOnboarding = hideOnboarding
        self.hideGettingStartedVideo = hideGettingStartedVideo
        self.selectedIncidentId = selectedIncidentId
        self.languageKey = languageKey
        self.syncAttempt = nil
        self.tableViewSortBy = tableViewSortBy
        self.shareLocationWithOrg = shareLocationWithOrg
        self.notifyDataSyncProgress = notifyDataSyncProgress
        self.casesMapBounds = casesMapBounds
        self.teamMapBounds = teamMapBounds
        self.isWorkScreenTableView = isWorkScreenTableView
    }
}
