// sourcery: copyBuilder, skipCopyInit
public struct AppPreferences: Codable {
    let hideOnboarding: Bool
    let selectedIncidentId: Int64
    let languageKey: String
    let syncAttempt: SyncAttempt
    let tableViewSortBy: WorksiteSortBy

    init(
        hideOnboarding: Bool = false,
        selectedIncidentId: Int64 = 0,
        languageKey: String = "en-US",
        syncAttempt: SyncAttempt = SyncAttempt(),
        tableViewSortBy: WorksiteSortBy = .none
    ) {
        self.hideOnboarding = hideOnboarding
        self.selectedIncidentId = selectedIncidentId
        self.languageKey = languageKey
        self.syncAttempt = syncAttempt
        self.tableViewSortBy = tableViewSortBy
    }
}
