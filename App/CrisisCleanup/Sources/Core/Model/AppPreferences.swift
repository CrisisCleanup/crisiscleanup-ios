// sourcery: copyBuilder, skipCopyInit
public struct AppPreferences: Codable {
    let selectedIncidentId: Int64
    let languageKey: String
    let syncAttempt: SyncAttempt
    let tableViewSortBy: WorksiteSortBy

    init(
        selectedIncidentId: Int64 = 0,
        languageKey: String = "en-US",
        syncAttempt: SyncAttempt = SyncAttempt(),
        tableViewSortBy: WorksiteSortBy = .none
    ) {
        self.selectedIncidentId = selectedIncidentId
        self.languageKey = languageKey
        self.syncAttempt = syncAttempt
        self.tableViewSortBy = tableViewSortBy
    }
}
