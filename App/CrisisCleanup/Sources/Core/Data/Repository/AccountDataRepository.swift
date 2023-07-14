import Combine

public protocol AccountDataRepository {
    var accountData: any Publisher<AccountData, Never> { get }

    var isAuthenticated: any Publisher<Bool, Never> { get }

    var refreshToken: String { get}
    var accessToken: String { get }

    func setAccount(
        refreshToken: String,
        accessToken: String,
        id: Int64,
        email: String,
        firstName: String,
        lastName: String,
        expirySeconds: Int64,
        profilePictureUri: String,
        org: OrgData
    )

    func updateAccountTokens(
        refreshToken: String,
        accessToken: String,
        expirySeconds: Int64
    )

    func clearAccountTokens()
}

class CrisisCleanupAccountDataRepository: AccountDataRepository {
    internal let accountDataSubject = CurrentValueSubject<AccountData, Never>(emptyAccountData)
    let accountData: any Publisher<AccountData, Never>

    let isAuthenticated: any Publisher<Bool, Never>

    var refreshToken: String {
        let userId = accountDataSubject.value.id
        return secureDataSource.getAuthTokens(userId).0
    }

    private(set) var accessToken: String = ""

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
            .map { $0.hasAuthenticated() }

        accountDataSource.accountData
            .eraseToAnyPublisher()
            .sink(receiveValue: { sourceData in
                let authTokens = self.secureDataSource.getAuthTokens(sourceData.id)
                self.accessToken = authTokens.1
                self.accountDataSubject.value = sourceData.copy {
                    $0.areTokensValid = authTokens.0.isNotBlank
                }
            })
            .store(in: &disposables)

        authEventBus.logouts
            .eraseToAnyPublisher()
            .sink(receiveValue: { _ in
                self.onLogout()
            })
            .store(in: &disposables)
    }

    func setAccount(
        refreshToken: String,
        accessToken: String,
        id: Int64,
        email: String,
        firstName: String,
        lastName: String,
        expirySeconds: Int64,
        profilePictureUri: String,
        org: OrgData
    ) {
        do {
            try secureDataSource.saveAuthTokens(id, refreshToken, accessToken)
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

    func updateAccountTokens(
        refreshToken: String,
        accessToken: String,
        expirySeconds: Int64
    ) {
        let isClearing = refreshToken.isBlank
        do {
            let userId = accountDataSubject.value.id
            try secureDataSource.saveAuthTokens(
                userId,
                refreshToken,
                isClearing ? "" : accessToken
            )
            accountDataSource.updateExpiry(isClearing ? 0 : expirySeconds)
        } catch {
            logger.logError(error)
        }
    }

    func clearAccountTokens() {
        updateAccountTokens(
            refreshToken: "",
            accessToken: "",
            expirySeconds: 0
        )
    }

    private func clearAccount() {
        let userId = accountDataSubject.value.id
        accountDataSource.clearAccount()
        accessToken = ""
        secureDataSource.deleteAuthTokens(userId)
    }

    private func onLogout() {
        clearAccount()
    }

    internal func expireAccessToken() {
        accessToken = ""
        accountDataSource.expireAccessToken()
    }
}
