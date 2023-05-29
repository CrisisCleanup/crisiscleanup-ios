// sourcery: copyBuilder
struct AppPreferences: Codable {
    let selectedIncidentId: Int64
    let saveCredentialsPromptCount: Int
    let disableSaveCredentialsPrompt: Bool
    let languageKey: String
    let syncAttempt: SyncAttempt

    init(
        selectedIncidentId: Int64 = 0,
        saveCredentialsPromptCount: Int = 0,
        disableSaveCredentialsPrompt: Bool = false,
        languageKey: String = "en-US",
        syncAttempt: SyncAttempt = SyncAttempt()
    ) {
        self.selectedIncidentId = selectedIncidentId
        self.saveCredentialsPromptCount = saveCredentialsPromptCount
        self.disableSaveCredentialsPrompt = disableSaveCredentialsPrompt
        self.languageKey = languageKey
        self.syncAttempt = syncAttempt
    }
}
