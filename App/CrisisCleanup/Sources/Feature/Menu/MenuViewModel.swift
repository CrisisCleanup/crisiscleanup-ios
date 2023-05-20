import SwiftUI
import Combine

protocol MenuViewModelProtocol: ObservableObject {
    var versionText: String { get }
}

class MenuViewModel: MenuViewModelProtocol {
    let appVersionProvider: AppVersionProvider

    var versionText: String {
        get {
            let version = appVersionProvider.version
            return "\(version.1) (\(version.0))"
        }
    }

    init(appVersionProvider: AppVersionProvider) {
        self.appVersionProvider = appVersionProvider
    }
}
