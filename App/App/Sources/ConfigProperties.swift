import Foundation

struct ConfigProperties: Codable {
    var isDebuggable: String
    var isProduction: String
    var apiBaseUrl: String
    var baseUrl: String
    var debugEmailAddress: String
    var debugAccountPassword: String
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
        debugEmailAddress: "",
        debugAccountPassword: ""
    )
}
