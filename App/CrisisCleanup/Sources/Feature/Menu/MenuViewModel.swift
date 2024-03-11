import Combine
import SwiftUI

class MenuViewModel: ObservableObject {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let accountDataRepository: AccountDataRepository
    private let accountDataRefresher: AccountDataRefresher
    private let incidentSelector: IncidentSelector
    private let appVersionProvider: AppVersionProvider
    private let databaseVersionProvider: DatabaseVersionProvider
    private let authEventBus: AuthEventBus
    private let appEnv: AppEnv
    private let logger: AppLogger

    let isDebuggable: Bool
    let isProduction: Bool

    let termsOfServiceUrl: URL
    let privacyPolicyUrl: URL

    @Published private(set) var showHeaderLoading = false

    @Published private(set) var profilePicture: AccountProfilePicture? = nil

    @Published private(set) var incidentsData = LoadingIncidentsData

    var versionText: String {
        let version = appVersionProvider.version
        return "\(version.1) (\(version.0)) \(appEnv.apiEnvironment) iOS"
    }

    var databaseVersionText: String {
        isProduction ? "" : "DB \(databaseVersionProvider.databaseVersion)"
    }

    private var subscriptions = Set<AnyCancellable>()

    init(
        incidentsRepository: IncidentsRepository,
        worksitesRepository: WorksitesRepository,
        accountDataRepository: AccountDataRepository,
        accountDataRefresher: AccountDataRefresher,
        syncLogRepository: SyncLogRepository,
        incidentSelector: IncidentSelector,
        appVersionProvider: AppVersionProvider,
        appSettingsProvider: AppSettingsProvider,
        databaseVersionProvider: DatabaseVersionProvider,
        authEventBus: AuthEventBus,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.accountDataRepository = accountDataRepository
        self.accountDataRefresher = accountDataRefresher
        self.incidentSelector = incidentSelector
        self.appVersionProvider = appVersionProvider
        self.databaseVersionProvider = databaseVersionProvider
        self.authEventBus = authEventBus
        self.appEnv = appEnv
        logger = loggerFactory.getLogger("menu")

        isDebuggable = appEnv.isDebuggable
        isProduction = appEnv.isProduction

        termsOfServiceUrl = appSettingsProvider.termsOfServiceUrl!
        privacyPolicyUrl = appSettingsProvider.privacyPolicyUrl!

        Task {
            syncLogRepository.trimOldLogs()
        }
    }

    func onViewAppear() {
        Task {
            await accountDataRefresher.updateProfilePicture()
        }

        subscribeLoading()
        subscribeIncidentsData()
        subscribeProfilePicture()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        Publishers.CombineLatest(
            incidentsRepository.isLoading.eraseToAnyPublisher(),
            worksitesRepository.isLoading.eraseToAnyPublisher()
        )
        .map { b0, b1 in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.showHeaderLoading, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeIncidentsData() {
        incidentSelector.incidentsData
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentsData, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeProfilePicture() {
        accountDataRepository.accountData
            .eraseToAnyPublisher()
            .compactMap {
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
            .receive(on: RunLoop.main)
            .assign(to: \.profilePicture, on: self)
            .store(in: &subscriptions)
    }

    func clearRefreshToken() {
        if isDebuggable {
            accountDataRepository.clearAccountTokens()
        }
    }

    func expireToken() {
        if isDebuggable {
            if let repository = accountDataRepository as? CrisisCleanupAccountDataRepository {
                repository.expireAccessToken()
            }
        }
    }
}

struct AccountProfilePicture {
    let url: URL
    let isSvg: Bool
}
