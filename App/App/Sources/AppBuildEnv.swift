import CrisisCleanup

struct AppBuildEnv : AppEnv {
    var isDebuggable: Bool
    var isProduction: Bool
    var isNotProduction: Bool

    init(_ config: ConfigProperties) {
        self.isDebuggable = config.isDebuggable=="YES"
        self.isProduction = config.isProduction=="YES"
        self.isNotProduction = !self.isProduction
    }

    func runInNonProd(block: () -> Void) {
        if self.isNotProduction {
            block()
        }
    }
}
