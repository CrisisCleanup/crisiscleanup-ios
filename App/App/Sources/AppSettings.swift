import CrisisCleanup

struct AppSettings : AppSettingsProvider {
    var apiBaseUrl: String
    var baseUrl: String
    var debugEmailAddress: String
    var debugAccountPassword: String

    init(_ config: ConfigProperties) {
        self.apiBaseUrl = config.apiBaseUrl
        self.baseUrl = config.baseUrl
        self.debugEmailAddress = config.debugEmailAddress
        self.debugAccountPassword = config.debugAccountPassword
    }
}
