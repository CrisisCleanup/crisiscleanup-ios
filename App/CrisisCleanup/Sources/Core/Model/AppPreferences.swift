// sourcery: copyBuilder
public struct AppPreferences: Codable {
    let selectedIncidentId: Int64
    let languageKey: String
    let syncAttempt: SyncAttempt

    init(
        selectedIncidentId: Int64 = 0,
        languageKey: String = "en-US",
        syncAttempt: SyncAttempt = SyncAttempt()
    ) {
        self.selectedIncidentId = selectedIncidentId
        self.languageKey = languageKey
        self.syncAttempt = syncAttempt
    }
}
