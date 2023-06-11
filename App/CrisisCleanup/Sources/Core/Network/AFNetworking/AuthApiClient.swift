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
}
