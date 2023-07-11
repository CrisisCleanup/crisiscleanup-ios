import Combine
import Foundation

public protocol SyncLogRepository {
    func streamLogCount() -> any Publisher<Int, Never>

    func getLogs(_ limit: Int, _ offset: Int) -> [SyncLog]

    func trimOldLogs()
}

class PagingSyncLogRepository: SyncLogger, SyncLogRepository {
    private let syncLogDao: SyncLogDao
    private let appEnv: AppEnv
    var type: String

    private let logEntriesLock = NSLock()
    private var logEntries = [SyncLog]()

    private var disableLoging: Bool { appEnv.isNotProduction }

    init(
        syncLogDao: SyncLogDao,
        appEnv: AppEnv,
        type: String = ""
    ) {
        self.syncLogDao = syncLogDao
        self.appEnv = appEnv
        self.type = type
    }

    // MARK: SyncLogger

    func log(
        _ message: String,
        _ details: String,
        _ type: String
    ) {
        if disableLoging { return }

        // TODO: Enable logging only if dev mode/sync logging is enabled
        let logType = type.ifBlank { self.type }
        logEntriesLock.withLock {
            logEntries.append(
                SyncLog(
                    id: nil,
                    logTime: Date.now,
                    logType: logType,
                    message: message,
                    details: details
                )
            )
        }

        // TODO: Delete when logs can be inspected
        print("\(logType) \(message) \(details)")
    }

    func clear() {
        if disableLoging { return }

        logEntriesLock.withLock {
            logEntries = []
        }
    }

    func flush() {
        if disableLoging { return }

        Task {
            var entries: [SyncLog] = []
            logEntriesLock.withLock {
                entries = logEntries
                logEntries = []
            }
            if entries.isNotEmpty {
                do {
                    try await syncLogDao.insertSyncLogs(entries.map { $0.asRecord() })
                } catch {
                    print("sync-log-exception \(error)")
                }
            }
        }
    }

    // MARK: SyncLogRepository

    func streamLogCount() -> any Publisher<Int, Never> { syncLogDao.streamLogCount() }

    func getLogs(_ limit: Int, _ offset: Int) -> [SyncLog] {
        syncLogDao.getSyncLogs(limit, offset)
            .map { $0.asExternalModel() }
    }

    func trimOldLogs() {
        Task {
            await syncLogDao.trimOldSyncLogs()
        }
    }
}
