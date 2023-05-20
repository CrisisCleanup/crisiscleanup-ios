import Foundation

public protocol AppVersionProvider {
    var version: (Int64, String) {get}
    var versionString: String {get}
    var buildNumber: Int64 {get}
}

protocol DatabaseVersionProvider {
    var databaseVersion: Int {get}
}

class AppleAppVersionProvider : AppVersionProvider {
    var version: (Int64, String) {
        get {
            let dictionary = Bundle.main.infoDictionary!
            let versionString = dictionary["CFBundleShortVersionString"] as! String
            let build = Int64(dictionary["CFBundleVersion"] as! String) ?? 0
            return (build, versionString)
        }
    }

    var versionString: String {
        get { return version.1 }
    }

    var buildNumber: Int64 {
        get { return version.0 }
    }
}
