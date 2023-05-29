public protocol AppLogger {
    func logDebug(_ items: Any...)
    func logError(_ e: Error)
}

public protocol AppLoggerFactory {
    func getLogger(_ tag: String) -> AppLogger
}
