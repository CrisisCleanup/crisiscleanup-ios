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

    private var subscriptions = Set<AnyCancellable>()

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
    }

    func onViewAppear() {
        subscribeIncidentsData()
        subscribeToProfilePicture()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeIncidentsData() {
        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToProfilePicture() {
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
            .assign(to: \.profilePicture, on: self)
            .store(in: &subscriptions)
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
