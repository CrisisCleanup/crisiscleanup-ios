// sourcery: AutoMockable
public protocol AppLogger {
    func logDebug(_ items: Any...)
    func logError(_ e: Error)
    func logCapture(_ message: String)
    func setAccountId(_ id: String)
}

public protocol AppLoggerFactory {
    func getLogger(_ tag: String) -> AppLogger
}
