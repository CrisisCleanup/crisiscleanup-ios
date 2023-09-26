import Atomics
import Foundation

class AccountApiClient : CrisisCleanupAccountApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    init(
        networkRequestProvider: NetworkRequestProvider,
        appEnv: AppEnv
    ) {
        // TODO: Test coverage. Including locale and time zone.
        let isoFormat = with(DateFormatter()) {
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        }
        let millisecondsFormat = with(DateFormatter()) {
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        }
        let jsonDecoder = JsonDecoderFactory().decoder(
            dateDecodingStrategy: .anyFormatter(in: [isoFormat, millisecondsFormat])
        )

        self.networkClient = AFNetworkingClient(appEnv, jsonDecoder: jsonDecoder)
        requestProvider = networkRequestProvider
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
        guard let result = await networkClient.callbackContinue(
            requestConvertible: request,
            type: InitiatePasswordResetResult.self
        ).value else {
            throw GenericError("Unable to parse initiate password request response")
        }
        return result
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
