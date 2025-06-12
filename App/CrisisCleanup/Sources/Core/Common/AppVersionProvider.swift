import Foundation

// sourcery: AutoMockable
public protocol AppVersionProvider {
    var version: (Int64, String) { get }
    var versionString: String { get }
    var buildNumber: Int64 { get }
}

public protocol DatabaseVersionProvider {
    var databaseVersion: Int32 { get }
}

class AppleAppVersionProvider : AppVersionProvider {
    var version: (Int64, String) {
        let dictionary = Bundle.main.infoDictionary!
        let versionString = dictionary["CFBundleShortVersionString"] as! String
        let build = Int64(dictionary["CFBundleVersion"] as! String) ?? 0
        return (build, versionString)
    }

    var versionString: String { version.1 }

    var buildNumber: Int64 { version.0 }
}
