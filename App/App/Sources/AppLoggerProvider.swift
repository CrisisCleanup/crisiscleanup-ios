import CrisisCleanup
import Firebase

class TagLogger: AppLogger {
    let appEnv: AppEnv
    let tag: String

    init(appEnv: AppEnv, tag: String) {
        self.appEnv = appEnv
        self.tag = tag
    }

    func logDebug(_ items: Any...) {
        if appEnv.isDebuggable {
            print(self.tag, items)
        }
    }

    func logError(_ e: Error) {
        if e is CancellationError {
            return
        }

        Crashlytics.crashlytics().record(error: e)

        if appEnv.isDebuggable {
            print(self.tag, e)
        }
    }
}

class AppLoggerProvider: AppLoggerFactory {
    let appEnv: AppEnv

    init(_ appEnv: AppEnv) {
        self.appEnv = appEnv
    }

    func getLogger(_ tag: String = "app") -> AppLogger {
        return TagLogger(appEnv: self.appEnv, tag: tag)
    }
}
