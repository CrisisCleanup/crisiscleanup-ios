public protocol AppLogger {
    func logDebug(_ items: Any...)
    func logError(e: Error)
}

public protocol AppLoggerFactory {
    func getLogger(_ tag: String) -> AppLogger
}
