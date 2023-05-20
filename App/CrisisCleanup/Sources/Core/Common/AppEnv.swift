public protocol AppEnv {
    var isDebuggable: Bool { get }
    var isProduction: Bool { get }
    var isNotProduction: Bool { get }
    func runInNonProd(block: () -> Void)
}
