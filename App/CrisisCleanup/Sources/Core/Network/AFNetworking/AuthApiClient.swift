import Foundation

class AuthApiClient : CrisisCleanupAuthApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let jsonDecoder: JSONDecoder

    init(appEnv: AppEnv,
         networkRequestProvider: NetworkRequestProvider
    ) {
        self.networkClient = AFNetworkingClient(appEnv)
        requestProvider = networkRequestProvider

        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
    }

    func login(_ email: String, _ password: String) async throws -> NetworkAuthResult {
        let payload = NetworkAuthPayload(email: email, password: password)
        let authRequest = requestProvider.login.copy {
            $0.parameters = payload
        }
        let result = await withCheckedContinuation { continuation in
            networkClient.request(authRequest)
                .responseDecodable(of: NetworkAuthResult.self,
                                   decoder: jsonDecoder) { response in
                    continuation.resume(returning: response)
                }
        }
        return result.value!
    }
}
