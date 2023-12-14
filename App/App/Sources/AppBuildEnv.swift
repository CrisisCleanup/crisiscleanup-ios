import CrisisCleanup

struct AppBuildEnv : AppEnv {
    let isDebuggable: Bool
    let isProduction: Bool
    var isNotProduction: Bool { !isProduction }

    let apiEnvironment: String

    init(_ config: ConfigProperties) {
        self.isDebuggable = config.isDebuggable=="YES"
        self.isProduction = config.isProduction=="YES"

        apiEnvironment = {
            let apiUrl = config.apiBaseUrl
            if apiUrl.starts(with: "https://api.dev.crisiscleanup.io") { return "Dev" }
            else if apiUrl.starts(with: "https://api.staging.crisiscleanup.io") { return "Staging" }
            else if apiUrl.starts(with: "https://api.crisiscleanup.org") { return "Production" }
            else if apiUrl.starts(with: "https://api.au.crisiscleanup.io") { return "Prodauction" }
            else { return "Local?" }
        }()
    }

    init() {
        isDebuggable = false
        isProduction = true
        apiEnvironment = "?"
    }

    func runInNonProd(block: () -> Void) {
        if self.isNotProduction {
            block()
        }
    }
}
