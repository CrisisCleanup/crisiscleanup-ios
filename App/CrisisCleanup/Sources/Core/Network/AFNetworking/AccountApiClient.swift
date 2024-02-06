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

        networkClient = AFNetworkingClient(appEnv, jsonDecoder: jsonDecoder)
        requestProvider = networkRequestProvider
    }

    func initiateMagicLink(_ emailAddress: String) async -> Bool {
        let payload = NetworkEmailPayload(email: emailAddress)
        let request = requestProvider.initiateMagicLink
            .setBody(payload)
        let result = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkMagicLinkResult.self
        )
        // TODO: Alert if account does not exist
        //       message = "User with this email does not exist."
        return result.response?.statusCode == 201 && result.value?.errors == nil
    }

    func initiatePhoneLogin(_ phoneNumber: String) async -> InitiatePhoneLoginResult {
        let payload = NetworkPhonePayload(phone: phoneNumber)
        let request = requestProvider.initiatePhoneLogin
            .setBody(payload)
        let result = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkPhoneCodeResult.self
        )
        // TODO: Capture and report errors accordingly
        if result.response?.statusCode == 201,
           result.value?.errors == nil {
            return .success
        }

        if let data = result.data {
            let resultMessage = String(decoding: data, as: UTF8.self)
            if resultMessage.contains("Invalid phone number") {
                return .phoneNotRegistered
            }
        }

        return .unknown
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
