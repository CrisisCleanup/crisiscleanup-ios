import Foundation

public protocol AppSettingsProvider {
    var apiBaseUrl: String { get }
    var appSupportApiBaseUrl: String { get }
    var baseUrl: String { get }
    var reachabilityHost: String { get }

    var googleMapsApiKey: String { get }

    var termsOfServiceUrl: URL? { get}
    var privacyPolicyUrl: URL? { get}
    var gettingStartedVideoUrl: URL? { get}

    var debugEmailAddress: String { get }
    var debugAccountPassword: String { get }
}
