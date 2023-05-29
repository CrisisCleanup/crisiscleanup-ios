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
    var accountData: Published<AccountData>.Publisher

    private(set) var accessTokenCached: String = ""

    @Published private var isAuthenticatedStream = false
    lazy var isAuthenticated = $isAuthenticatedStream

    private let accountDataSource: AccountInfoDataSource

    private var disposables = Set<AnyCancellable>()

    init(
        _ accountDataSource: AccountInfoDataSource,
        _ authEventBus: AuthEventBus
    ) {
        self.accountDataSource = accountDataSource

        accountData = accountDataSource.accountData
        accountData.map{ $0.accessToken.isNotBlank }
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
            accountDataSource.setAccount(AccountInfo(
                id: id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                expirySeconds: expirySeconds,
                profilePictureUri: profilePictureUri,
                accessToken: accessToken,
                orgId: org.id,
                orgName: org.name
            ))
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
