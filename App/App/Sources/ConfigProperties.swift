import Foundation

struct ConfigProperties: Codable {
    let isDebuggable: String
    let isProduction: String
    let apiBaseUrl: String
    let baseUrl: String
    let reachabilityHost: String
    let googleMapsApiKey: String
    let debugEmailAddress: String
    let debugAccountPassword: String
}

func loadConfigProperties() -> ConfigProperties {
    if let path = Bundle.main.path(forResource: "Info.plist", ofType: nil),
       let contents = FileManager.default.contents(atPath: path),
       let config = try? PropertyListDecoder().decode(ConfigProperties.self, from: contents) {
        return config
    }
    return ConfigProperties(
        isDebuggable: "NO",
        isProduction: "YES",
        apiBaseUrl: "",
        baseUrl: "",
        reachabilityHost: "",
        googleMapsApiKey: "",
        debugEmailAddress: "",
        debugAccountPassword: ""
    )
}
