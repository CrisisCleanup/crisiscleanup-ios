import Foundation

class AuthApiClient : CrisisCleanupAuthApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let jsonDecoder: JSONDecoder

    init(
        appEnv: AppEnv,
        networkRequestProvider: NetworkRequestProvider
    ) {
        self.networkClient = AFNetworkingClient(appEnv)
        requestProvider = networkRequestProvider

        jsonDecoder = JsonDecoderFactory().decoder()
    }

    func login(_ email: String, _ password: String) async throws -> NetworkAuthResult? {
        let payload = NetworkAuthPayload(email: email, password: password)
        let authRequest = requestProvider.login.copy {
            $0.bodyParameters = payload
        }
        return await networkClient.callbackContinue(
            requestConvertible: authRequest,
            type: NetworkAuthResult.self
        ).value
    }

    func oauthLogin(_ email: String, _ password: String) async throws -> NetworkOAuthResult? {
        let payload = NetworkOAuthPayload(username: email, password: password)
        let authRequest = requestProvider.oauthLogin.copy {
            $0.bodyParameters = payload
        }
        return await networkClient.callbackContinue(
            requestConvertible: authRequest,
            type: NetworkOAuthResult.self
        ).value
    }

    func refreshTokens(_ refreshToken: String) async throws -> NetworkOAuthResult? {
        let payload = NetworkRefreshToken(refreshToken: refreshToken)
        let refreshRequest = requestProvider.refreshAccountTokens.copy {
            $0.bodyParameters = payload
        }
        return await networkClient.callbackContinue(
            requestConvertible: refreshRequest,
            type: NetworkOAuthResult.self
        ).value
    }
}
