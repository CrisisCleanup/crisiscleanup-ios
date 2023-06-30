import SwiftUI
import Combine

class MenuViewModel: ObservableObject {
    private let appEnv: AppEnv
    private let accountDataRepository: AccountDataRepository
    private let incidentSelector: IncidentSelector
    private let appVersionProvider: AppVersionProvider
    private let databaseVersionProvider: DatabaseVersionProvider
    private let authEventBus: AuthEventBus
    private let logger: AppLogger

    let isDebuggable: Bool
    let isProduction: Bool

    @Published var profilePicture: AccountProfilePicture? = nil

    @Published private(set) var incidentsData = LoadingIncidentsData

    var versionText: String {
        let version = appVersionProvider.version
        return isProduction ? version.1 : "\(version.1) (\(version.0))"
    }

    var databaseVersionText: String {
        isProduction ? "" : "DB \(databaseVersionProvider.databaseVersion)"
    }

    private var disposables = Set<AnyCancellable>()

    init(
        appEnv: AppEnv,
        accountDataRepository: AccountDataRepository,
        incidentSelector: IncidentSelector,
        appVersionProvider: AppVersionProvider,
        databaseVersionProvider: DatabaseVersionProvider,
        authEventBus: AuthEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.accountDataRepository = accountDataRepository
        self.incidentSelector = incidentSelector
        self.appVersionProvider = appVersionProvider
        self.databaseVersionProvider = databaseVersionProvider
        self.authEventBus = authEventBus
        logger = loggerFactory.getLogger("menu")

        isDebuggable = appEnv.isDebuggable
        isProduction = appEnv.isProduction

        accountDataRepository.accountData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .map {
                let pictureUrl = $0.profilePictureUri
                let isSvg = pictureUrl.hasSuffix(".svg")
                if let escapedUrl = isSvg ? pictureUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) : pictureUrl,
                   let url = URL(string: escapedUrl) {
                    return AccountProfilePicture(
                        url: url,
                        isSvg: isSvg
                    )
                }
                return nil
            }
            .assign(to: &$profilePicture)

        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { self.incidentsData = $0 }
            .store(in: &disposables)
    }

    func onViewAppear() {
        // TODO: Resume observations
    }

    func onViewDisappear() {
        // TODO: Pause observations
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
