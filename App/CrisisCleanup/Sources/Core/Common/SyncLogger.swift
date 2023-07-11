public protocol SyncLogger {
    var type: String { get set }
    func log(_ message: String, _ details: String, _ type: String)
    func clear()
    func flush()
}

extension SyncLogger {
    func log(_ message: String, details: String = "", type: String = "") {
        log(message, details, type)
    }
}

public protocol SyncLoggerFactory {
    func getLogger(_ type: String) -> SyncLogger
}
