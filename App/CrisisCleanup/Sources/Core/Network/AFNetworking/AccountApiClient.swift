import Atomics
import Foundation

class AccountApiClient : CrisisCleanupAccountApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let jsonDecoder: JSONDecoder

    init(
        networkRequestProvider: NetworkRequestProvider,
        appEnv: AppEnv
    ) {
        self.networkClient = AFNetworkingClient(appEnv)
        requestProvider = networkRequestProvider

        jsonDecoder = JsonDecoderFactory().decoder()
    }

    func initiateMagicLink(_ emailAddress: String) async -> Bool {
        let payload = NetworkEmailPayload(email: emailAddress)
        let request = requestProvider.initiateMagicLink
            .setBody(payload)
        return await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkMagicLinkResult.self
        ).value?.detail.isNotBlank == true
    }

    func initiatePasswordReset(_ emailAddress: String) async throws -> InitiatePasswordResetResult {
        let payload = NetworkEmailPayload(email: emailAddress)
        let request = requestProvider.initiatePasswordReset
            .setBody(payload)
        return try await networkClient.callbackContinue(
            requestConvertible: request,
            type: InitiatePasswordResetResult.self
        ).value ?? { throw GenericError("No response for initiate password request") }()
    }

    func changePassword(password: String, token: String) async -> Bool {
        let payload = NetworkPasswordResetPayload(password: password, token: token)
        let request = requestProvider.resetPassword
            .addPaths(token, "reset")
            .setBody(payload)
        let status = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkPasswordResetResult.self
        ).value?.status ?? ""
        return status.isNotBlank && status != "invalid"
    }
}
