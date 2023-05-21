import SwiftUI
import Combine

protocol MenuViewModelProtocol: ObservableObject {
    var versionText: String { get }
}

class MenuViewModel: MenuViewModelProtocol {
    let appEnv: AppEnv
    let appVersionProvider: AppVersionProvider
    let logger: AppLogger

    var versionText: String {
        let version = appVersionProvider.version
        return "\(version.1) (\(version.0))"
    }

    init(
        appEnv: AppEnv,
        appVersionProvider: AppVersionProvider,
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.appVersionProvider = appVersionProvider
        self.logger = loggerFactory.getLogger("menu")
    }
}
