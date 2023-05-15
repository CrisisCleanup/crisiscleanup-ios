import SwiftUI
import Combine

@MainActor
public class MenuViewModel: ObservableObject {
    // TODO Inject
    let appVersionProvider: AppVersionProvider

    var versionText: String {
        get {
            let version = appVersionProvider.version
            return "\(version.1) (\(version.0))"
        }
    }

    public init() {
        appVersionProvider = AppleAppVersionProvider()
    }
}
