import Atomics
import Alamofire
import Combine
import Foundation

private let jsonDecoder = JsonDecoderFactory().decoder()

class AccessTokenInterceptor: RequestInterceptor {
    private let accountDataRepository: AccountDataRepository
    private let accountDataPublisher: AnyPublisher<AccountData, Never>
    private let authApiClient: CrisisCleanupAuthApi
    private let authEventBus: AuthEventBus

    private let refreshTokensGuard = ManagedAtomic(false)

    private let invalidRefreshTokenErrorMessages: Set<String> = [
        "refresh_token_already_revoked",
        "invalid_refresh_token",
    ]

    init(
        accountDataRepository: AccountDataRepository,
        authApiClient: CrisisCleanupAuthApi,
        authEventBus: AuthEventBus
    ) {
        self.accountDataRepository = accountDataRepository
        accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()

        self.authApiClient = authApiClient
        self.authEventBus = authEventBus
    }

    func adapt(
        _ urlRequest: URLRequest,
        using state: RequestAdapterState,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        if urlRequest.value(forHTTPHeaderField: "Authorization") == "" {
            // TODO: Research a better pattern if one exists
            Task {
                do {
                    let authRequest = try await setRequestAuthorization(urlRequest)
                    return completion(.success(authRequest))
                } catch {
                    return completion(.failure(error))
                }
            }
        } else {
            completion(.success(urlRequest))
        }
    }

    private func setRequestAuthorization(_ urlRequest: URLRequest) async throws -> URLRequest {
        let accountData = try await accountDataPublisher.asyncFirst()
        if !accountData.areTokensValid {
            throw ExpiredTokenError()
        }

        if accountData.isAccessTokenExpired() {
            if !refreshTokensGuard.exchange(true, ordering: .sequentiallyConsistent) {
                do {
                    defer { refreshTokensGuard.store(false, ordering: .sequentiallyConsistent)}

                    if try await !refreshTokens() {
                        throw ExpiredTokenError()
                    }
                }
            } else {
                throw ExpiredTokenError()
            }
        }

        let accessToken = accountDataRepository.accessToken

        var authRequest = urlRequest
        authRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return authRequest
    }

    private func refreshTokens() async throws -> Bool {
        let refreshToken = accountDataRepository.refreshToken
        if refreshToken.isNotBlank {
            if let refreshResult = try await authApiClient.refreshTokens(refreshToken) {
                if refreshResult.error == nil {
                    let expiresIn = Double(refreshResult.expiresIn!)
                    let expiryDate = Date().addingTimeInterval(expiresIn.seconds)
                    accountDataRepository.updateAccountTokens(
                        refreshToken: refreshResult.refreshToken!,
                        accessToken: refreshResult.accessToken!,
                        expirySeconds: Int64(expiryDate.timeIntervalSince1970)
                    )
                    authEventBus.onTokensRefreshed()
                    return true
                } else {
                    if invalidRefreshTokenErrorMessages.contains(refreshResult.error!) {
                        accountDataRepository.clearAccountTokens()
                    }
                }
            }
        }
        return false
    }
}
