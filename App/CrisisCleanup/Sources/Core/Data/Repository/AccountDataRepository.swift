import Combine

public protocol AccountDataRepository {
    var accountData: Published<AccountData>.Publisher { get }

    var accessTokenCached: String { get }

    var isAuthenticated: Published<Bool>.Publisher { get }

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
    @Published private var accountDataStream = emptyAccountData
    lazy var accountData = $accountDataStream

    private(set) var accessTokenCached: String = ""

    @Published private var isAuthenticatedStream = false
    lazy var isAuthenticated = $isAuthenticatedStream

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

        accountDataSource.accountData.map { sourceData in
            let email = sourceData.emailAddress
            if email.isNotBlank {
                let accessToken = secureDataSource.getAccessToken(email)
                return sourceData.copy {
                    $0.accessToken = accessToken
                }
            }
            return sourceData
        }
        .assign(to: &accountData)
        accountData
            .sink { data in
                self.accessTokenCached = data.accessToken
            }
            .store(in: &disposables)
        accountData.map { $0.accessToken.isNotBlank }
            .assign(to: &isAuthenticated)

        authEventBus.logouts
            .filter({ b in b })
            .sink { [weak self] _ in
                await self?.onLogout()
            }
            .store(in: &disposables)
        authEventBus.expiredTokens
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
