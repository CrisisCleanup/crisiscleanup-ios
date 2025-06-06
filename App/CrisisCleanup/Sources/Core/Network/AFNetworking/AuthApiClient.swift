import Atomics
import Foundation

class AuthApiClient : CrisisCleanupAuthApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let jsonDecoder: JSONDecoder

    private let refreshTokensGuard = ManagedAtomic(false)

    init(
        appEnv: AppEnv,
        networkRequestProvider: NetworkRequestProvider
    ) {
        self.networkClient = AFNetworkingClient(appEnv)
        requestProvider = networkRequestProvider

        jsonDecoder = JsonDecoderFactory().decoder()
    }

    private func trySleepRandom() async throws {
        let sleepNanos = 1_000_000_000 + UInt64.random(in: 100_000_000...500_000_000)
        try await Task.sleep(nanoseconds: sleepNanos)
    }

    func login(_ email: String, _ password: String) async throws -> NetworkAuthResult? {
        let payload = NetworkAuthPayload(email: email, password: password)
        let authRequest = requestProvider.login
            .setBody(payload)

        for _ in 0..<3 {
            let loginResult = await networkClient.callbackContinue(
                requestConvertible: authRequest,
                type: NetworkAuthResult.self
            ).value
            if loginResult?.claims != nil {
                return loginResult
            }
            try await trySleepRandom()
        }
        return nil
    }

    func oauthLogin(_ email: String, _ password: String) async throws -> NetworkOAuthResult? {
        let payload = NetworkOAuthPayload(username: email, password: password)
        let authRequest = requestProvider.oauthLogin
            .setBody(payload)

        for _ in 0..<3 {
            let oauthResult = await networkClient.callbackContinue(
                requestConvertible: authRequest,
                type: NetworkOAuthResult.self
            ).value
            if oauthResult?.accessToken != nil {
                return oauthResult
            }
            try await trySleepRandom()
        }
        return nil
    }

    func magicLinkLogin(_ token: String) async throws -> NetworkOAuthTokens? {
        let authRequest = requestProvider.magicLinkCodeAuth
            .addPaths(token, "login")
        return await networkClient.callbackContinue(
            requestConvertible: authRequest,
            type: NetworkCodeAuthResult.self,
            wrapResponseKey: "authTokens"
        ).value?.authTokens
    }

    func verifyPhoneCode(phoneNumber: String, code: String) async -> NetworkOneTimePasswordResult? {
        let payload = NetworkPhoneCodePayload(phone: phoneNumber, code: code)
        let request = requestProvider.verifyOneTimePassword
            .setBody(payload)
        let result = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkPhoneOneTimePasswordResult.self,
            wrapResponseKey: "otpResult"
        )
        // TODO: Capture and report errors accordingly
        return result.value?.otpResult
    }

    func oneTimePasswordLogin(accountId: Int64, oneTimePasswordId: Int64) async throws -> NetworkOAuthTokens? {
        let payload = NetworkOneTimePasswordPayload(accountId: accountId, otpId: oneTimePasswordId)
        let authRequest = requestProvider.oneTimePasswordAuth
            .setBody(payload)
        return await networkClient.callbackContinue(
            requestConvertible: authRequest,
            type: NetworkCodeAuthResult.self,
            wrapResponseKey: "authTokens"
        ).value?.authTokens
    }

    /**
     * - Returns nil if the network call was not attempted (due to onging call) or the result otherwise
     */
    func refreshTokens(_ refreshToken: String) async throws -> NetworkOAuthResult? {
        if !refreshTokensGuard.exchange(true, ordering: .sequentiallyConsistent) {
            do {
                defer { refreshTokensGuard.store(false, ordering: .sequentiallyConsistent)}

                let payload = NetworkRefreshToken(refreshToken: refreshToken)
                let refreshRequest = requestProvider.refreshAccountTokens
                    .setBody(payload)
                return await networkClient.callbackContinue(
                    requestConvertible: refreshRequest,
                    type: NetworkOAuthResult.self
                ).value
            }
        }

        return nil
    }
}
