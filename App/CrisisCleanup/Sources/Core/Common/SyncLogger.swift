public protocol SyncLogger {
    func log(_ message: String, _ details: String, _ type: String) -> SyncLogger
    func clear() -> SyncLogger
    func flush()
}

extension SyncLogger {
    func log(_ message: String, _ details: String) -> SyncLogger {
        return log(message, details, "")
    }

    func log(_ message: String) -> SyncLogger {
        return log(message, "")
    }
}

public protocol SyncLoggerFactory {
    func getLogger(_ type: String) -> SyncLogger
}
