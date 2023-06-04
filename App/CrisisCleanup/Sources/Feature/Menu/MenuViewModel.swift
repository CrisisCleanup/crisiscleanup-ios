import SwiftUI
import Combine

class MenuViewModel: ObservableObject {
    private let appEnv: AppEnv
    private let accountDataRepository: AccountDataRepository
    private let appVersionProvider: AppVersionProvider
    private let authEventBus: AuthEventBus
    private let logger: AppLogger

    let isDebuggable: Bool

    @Published var profilePicture: AccountProfilePicture? = nil

    var versionText: String {
        let version = appVersionProvider.version
        return "\(version.1) (\(version.0))"
    }

    private var disposables = Set<AnyCancellable>()

    init(
        appEnv: AppEnv,
        accountDataRepository: AccountDataRepository,
        appVersionProvider: AppVersionProvider,
        authEventBus: AuthEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.accountDataRepository = accountDataRepository
        self.appVersionProvider = appVersionProvider
        self.authEventBus = authEventBus
        logger = loggerFactory.getLogger("menu")

        isDebuggable = appEnv.isDebuggable

        accountDataRepository.accountData
            .map{
                if let escapedUrl = $0.profilePictureUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: escapedUrl) {
                    return AccountProfilePicture(
                        url: url,
                        isSvg: $0.profilePictureUri.hasSuffix(".svg")
                    )
                }
                return nil
            }
            .assign(to: &$profilePicture)
    }

    func expireToken() {
        if isDebuggable {
            authEventBus.onExpiredToken()
        }
    }
}

struct AccountProfilePicture {
    let url: URL
    let isSvg: Bool
}
