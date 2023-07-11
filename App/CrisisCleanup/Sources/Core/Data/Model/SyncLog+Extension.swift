extension SyncLog {
    func asRecord() -> SyncLogRecord {
        SyncLogRecord(
            logTime: logTime,
            logType: logType,
            message: message,
            details: details
        )
    }
}
