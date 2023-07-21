import CrisisCleanup

struct AppSettings : AppSettingsProvider {
    let apiBaseUrl: String
    let baseUrl: String
    let googleMapsApiKey: String
    let debugEmailAddress: String
    let debugAccountPassword: String

    init(_ config: ConfigProperties) {
        self.apiBaseUrl = config.apiBaseUrl
        self.baseUrl = config.baseUrl
        self.googleMapsApiKey = config.googleMapsApiKey
        self.debugEmailAddress = config.debugEmailAddress
        self.debugAccountPassword = config.debugAccountPassword
    }

    init() {
        apiBaseUrl = ""
        baseUrl = ""
        googleMapsApiKey = ""
        debugEmailAddress = ""
        debugAccountPassword = ""
    }
}
