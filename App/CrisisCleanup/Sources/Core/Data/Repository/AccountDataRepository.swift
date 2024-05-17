import Atomics
import Combine
import Foundation

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
        org: OrgData,
        hasAcceptedTerms: Bool,
        activeRoles: Set<Int>
    )

    func updateAccountTokens(
        refreshToken: String,
        accessToken: String,
        expirySeconds: Int64
    )

    func updateAccountTokens() async

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
    private let preferencesDataSource: AppPreferencesDataStore
    private let authApi: CrisisCleanupAuthApi
    private let accountApi: CrisisCleanupAccountApi
    private let logger: AppLogger
    private let appEnv: AppEnv

    private var disposables = Set<AnyCancellable>()

    init(
        _ accountDataSource: AccountInfoDataSource,
        _ secureDataSource: SecureDataSource,
        _ preferencesDataSource: AppPreferencesDataStore,
        _ authEventBus: AuthEventBus,
        _ authApi: CrisisCleanupAuthApi,
        _ accountApi: CrisisCleanupAccountApi,
        _ loggerFactory: AppLoggerFactory,
        _ appEnv: AppEnv
    ) {
        self.accountDataSource = accountDataSource
        self.secureDataSource = secureDataSource
        self.preferencesDataSource = preferencesDataSource
        self.authApi = authApi
        self.accountApi = accountApi
        logger = loggerFactory.getLogger("account")
        self.appEnv = appEnv

        accountData = accountDataSubject

        let accountDataShare = accountData
            .eraseToAnyPublisher()

        isAuthenticated = accountDataShare
            .map { $0.hasAuthenticated }

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
        org: OrgData,
        hasAcceptedTerms: Bool,
        activeRoles: Set<Int>
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
                orgName: org.name,
                hasAcceptedTerms: hasAcceptedTerms,
                activeRoles: activeRoles
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

    func updateAccountTokens() async
    {
        do {
            let accountData = accountDataSubject.value
            let now = Date.now
            if accountData.areTokensValid &&
                accountData.tokenExpiry < now.addingTimeInterval(10.minutes) {
                if let refreshResult = try await authApi.refreshTokens(refreshToken),
                   refreshResult.error == nil {
                    let expiresSeconds = Double(refreshResult.expiresIn!)
                    let expiryDate = now.addingTimeInterval(expiresSeconds)
                    updateAccountTokens(
                        refreshToken: refreshResult.refreshToken!,
                        accessToken: refreshResult.accessToken!,
                        expirySeconds: Int64(expiryDate.timeIntervalSince1970)
                    )
                    logger.logDebug("Refreshed soon/expiring account tokens")
                }
            }
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
        preferencesDataSource.reset()
    }

    private let skipChangeGuard = ManagedAtomic(false)
    internal func expireAccessToken() {
        if appEnv.isNotProduction {
            skipChangeGuard.store(true, ordering: .sequentiallyConsistent)
            accessToken = ""
            accountDataSource.expireAccessToken()
        }
    }
}
