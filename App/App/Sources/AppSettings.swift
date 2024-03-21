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
    let gettingStartedVideoUrl: URL?
    let debugEmailAddress: String
    let debugAccountPassword: String

    init(_ config: ConfigProperties) {
        apiBaseUrl = config.apiBaseUrl
        appSupportApiBaseUrl = config.appSupportApiBaseUrl
        baseUrl = config.baseUrl
        reachabilityHost = config.reachabilityHost
        googleMapsApiKey = config.googleMapsApiKey
        termsOfServiceUrl = URL(string: "\(baseUrl)/terms?view=plain")
        privacyPolicyUrl = URL(string: "\(baseUrl)/privacy?view=plain")
        gettingStartedVideoUrl = URL(string: config.gettingStartedVideoUrl)
        debugEmailAddress = config.debugEmailAddress
        debugAccountPassword = config.debugAccountPassword
    }

    init() {
        apiBaseUrl = ""
        appSupportApiBaseUrl = ""
        baseUrl = ""
        reachabilityHost = ""
        googleMapsApiKey = ""
        termsOfServiceUrl = nil
        privacyPolicyUrl = nil
        gettingStartedVideoUrl = nil
        debugEmailAddress = ""
        debugAccountPassword = ""
    }
}
