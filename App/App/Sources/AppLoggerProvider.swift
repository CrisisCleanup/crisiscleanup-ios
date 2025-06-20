import CrisisCleanup
import Firebase
import OSLog

class TagLogger: AppLogger {
    let appEnv: AppEnv
    let tag: String
    let osLogger: Logger

    private var crashlytics: Crashlytics { Crashlytics.crashlytics() }

    init(appEnv: AppEnv, tag: String) {
        self.appEnv = appEnv
        self.tag = tag
        osLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: tag)
    }

    func logDebug(_ items: Any...) {
        if appEnv.isDebuggable {
            let joined = items.map { "\($0)" }.joined(separator: ", ")
            osLogger.debug("\(joined, privacy: .public)")
        }
    }

    func logError(_ e: Error) {
        if e is CancellationError {
            return
        }

        if let genericError = e as? GenericError,
           genericError == ExpiredTokenError {
            return
        }

        if appEnv.isDebuggable {
            if let ge = e as? GenericError {
                osLogger.error("\(ge.message)")
            } else {
                osLogger.error("\(e.localizedDescription)")
                print(tag, e)
            }
        } else {
            if let ge = e as? GenericError {
                crashlytics.log(ge.message)
            }
            crashlytics.record(error: e)
        }
    }

    func logCapture(_ message: String) {
        if !appEnv.isDebuggable {
            crashlytics.log(message)
        }
    }

    func setAccountId(_ id: String) {
        crashlytics.setUserID(id)
    }
}

class AppLoggerProvider: AppLoggerFactory {
    let appEnv: AppEnv

    init(_ appEnv: AppEnv) {
        self.appEnv = appEnv
    }

    func getLogger(_ tag: String = "app") -> AppLogger {
        return TagLogger(appEnv: appEnv, tag: tag)
    }
}
