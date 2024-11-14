import CrisisCleanup
import Firebase

class TagLogger: AppLogger {
    let appEnv: AppEnv
    let tag: String

    private var crashlytics: Crashlytics { Crashlytics.crashlytics() }

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

        if let genericError = e as? GenericError,
           genericError == ExpiredTokenError {
            return
        }

        if appEnv.isDebuggable {
            if let ge = e as? GenericError {
                print(self.tag, ge.message)
            } else {
                print(self.tag, e)
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
        return TagLogger(appEnv: self.appEnv, tag: tag)
    }
}
