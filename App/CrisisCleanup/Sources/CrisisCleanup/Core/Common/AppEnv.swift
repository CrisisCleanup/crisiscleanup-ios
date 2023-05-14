protocol AppEnv {
    var isDebuggable: Bool {get}
    var isProduction: Bool {get}
    func runInNonProd(block: () -> Void)
}
