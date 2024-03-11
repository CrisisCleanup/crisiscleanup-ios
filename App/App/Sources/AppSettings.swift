import CrisisCleanup
import Foundation

struct AppSettings : AppSettingsProvider {
    let apiBaseUrl: String
    let appSupportApiBaseUrl: String
    let baseUrl: String
    let reachabilityHost: String
    let googleMapsApiKey: String
    let termsOfServiceUrl: URL?
    let privacyPolicyUrl: URL?
    let debugEmailAddress: String
    let debugAccountPassword: String

    init(_ config: ConfigProperties) {
        self.apiBaseUrl = config.apiBaseUrl
        self.appSupportApiBaseUrl = config.appSupportApiBaseUrl
        self.baseUrl = config.baseUrl
        self.reachabilityHost = config.reachabilityHost
        self.googleMapsApiKey = config.googleMapsApiKey
        termsOfServiceUrl = URL(string: "\(baseUrl)/terms?view=plain")
        privacyPolicyUrl = URL(string: "\(baseUrl)/privacy?view=plain")
        self.debugEmailAddress = config.debugEmailAddress
        self.debugAccountPassword = config.debugAccountPassword
    }

    init() {
        apiBaseUrl = ""
        appSupportApiBaseUrl = ""
        baseUrl = ""
        reachabilityHost = ""
        googleMapsApiKey = ""
        termsOfServiceUrl = nil
        privacyPolicyUrl = nil
        debugEmailAddress = ""
        debugAccountPassword = ""
    }
}
