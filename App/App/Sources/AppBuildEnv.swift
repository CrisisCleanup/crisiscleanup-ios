import CrisisCleanup
import Foundation

struct AppBuildEnv : AppEnv {
    let isDebuggable: Bool
    let isProduction: Bool
    var isNotProduction: Bool { !isProduction }

    let isAustraliaBuild: Bool

    let apiEnvironment: String

    init(_ config: ConfigProperties) {
        self.isDebuggable = config.isDebuggable=="YES"
        self.isProduction = config.isProduction=="YES"

        isAustraliaBuild = Bundle(for: AppDelegate.self).bundleIdentifier == "com.crisiscleanup.aus"

        apiEnvironment = {
            let apiUrl = config.apiBaseUrl
            if apiUrl.starts(with: "https://api.dev.crisiscleanup.io") { return "Dev" }
            else if apiUrl.starts(with: "https://crisiscleanup-3-api-staging.up.railway.app") { return "Staging" }
            else if apiUrl.starts(with: "https://api.crisiscleanup.org") { return "Production" }
            else if apiUrl.starts(with: "https://api.crisiscleanup.org.au") { return "Prodauction" }
            else { return "Local?" }
        }()
    }

    init() {
        isDebuggable = false
        isProduction = true
        apiEnvironment = "?"
        isAustraliaBuild = false
    }

    func runInNonProd(block: () -> Void) {
        if self.isNotProduction {
            block()
        }
    }
}
