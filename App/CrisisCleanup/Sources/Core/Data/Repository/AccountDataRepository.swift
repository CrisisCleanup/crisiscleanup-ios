import Combine

public protocol AccountDataRepository {
    var accountData: any Publisher<AccountData, Never> { get }

    var accessTokenCached: String { get }

    var isAuthenticated: any Publisher<Bool, Never> { get }

    func setAccount(
        id: Int64,
        accessToken: String,
        email: String,
        firstName: String,
        lastName: String,
        expirySeconds: Int64,
        profilePictureUri: String,
        org: OrgData
    )
}

class CrisisCleanupAccountDataRepository: AccountDataRepository {
    private let accountDataSubject = CurrentValueSubject<AccountData, Never>(emptyAccountData)
    let accountData: any Publisher<AccountData, Never>

    private(set) var accessTokenCached: String = ""

    let isAuthenticated: any Publisher<Bool, Never>

    private let accountDataSource: AccountInfoDataSource
    private let secureDataSource: SecureDataSource
    private let logger: AppLogger

    private var disposables = Set<AnyCancellable>()

    init(
        _ accountDataSource: AccountInfoDataSource,
        _ secureDataSource: SecureDataSource,
        _ authEventBus: AuthEventBus,
        _ loggerFactory: AppLoggerFactory
    ) {
        self.accountDataSource = accountDataSource
        self.secureDataSource = secureDataSource
        logger = loggerFactory.getLogger("account")

        accountData = accountDataSubject

        let accountDataShare = accountData
            .eraseToAnyPublisher()

        isAuthenticated = accountDataShare
            .map { $0.accessToken.isNotBlank }

        accountDataShare
            .sink { data in
                self.accessTokenCached = data.accessToken
            }
            .store(in: &disposables)

        accountDataSource.accountData
            .eraseToAnyPublisher()
            .map { sourceData in
                let email = sourceData.emailAddress
                if email.isNotBlank {
                    let accessToken = secureDataSource.getAccessToken(email)
                    return sourceData.copy {
                        $0.accessToken = accessToken
                    }
                }
                return sourceData
            }
            .sink(receiveCompletion: { completion in
            }, receiveValue: { sourceData in
                self.accountDataSubject.value = sourceData
            })
            .store(in: &disposables)

        authEventBus.logouts
            .eraseToAnyPublisher()
            .filter({ b in b })
            .sink { [weak self] _ in
                await self?.onLogout()
            }
            .store(in: &disposables)
        authEventBus.expiredTokens
            .eraseToAnyPublisher()
            .filter({ b in b })
            .sink { [weak self] _ in
                await self?.onExpiredToken()
            }
            .store(in: &disposables)
    }

    func setAccount(
        id: Int64,
        accessToken: String,
        email: String,
        firstName: String,
        lastName: String,
        expirySeconds: Int64,
        profilePictureUri: String,
        org: OrgData) {
            do {
                try secureDataSource.saveAccessToken(email, accessToken)
                accountDataSource.setAccount(AccountInfo(
                    id: id,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    expirySeconds: expirySeconds,
                    profilePictureUri: profilePictureUri,
                    accessToken: "",
                    orgId: org.id,
                    orgName: org.name
                ))
            } catch {
                logger.logError(error)
            }
        }

    private func clearAccount() {
        accessTokenCached = ""
        accountDataSource.clearAccount()
    }

    private func onLogout() async {
        clearAccount()
    }

    private func onExpiredToken() async {
        accessTokenCached = ""
        accountDataSource.expireToken()
    }
}
