import CrisisCleanup

struct AppBuildEnv : AppEnv {
    let isDebuggable: Bool
    let isProduction: Bool
    var isNotProduction: Bool { !isProduction }

    init(_ config: ConfigProperties) {
        self.isDebuggable = config.isDebuggable=="YES"
        self.isProduction = config.isProduction=="YES"
    }

    init() {
        isDebuggable = false
        isProduction = true
    }

    func runInNonProd(block: () -> Void) {
        if self.isNotProduction {
            block()
        }
    }
}
