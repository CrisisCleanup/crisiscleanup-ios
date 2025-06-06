import Foundation

class AccountApiClient : CrisisCleanupAccountApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let dateFormatter: ISO8601DateFormatter

    init(
        networkRequestProvider: NetworkRequestProvider,
        accountDataRepository: AccountDataRepository,
        authApiClient: CrisisCleanupAuthApi,
        accountEventBus: AccountEventBus,
        appEnv: AppEnv
    ) {
        dateFormatter = ISO8601DateFormatter()

        let jsonDecoder = JsonDecoderFactory().multiDateDecoder()

        networkClient = AFNetworkingClient(
            appEnv,
            interceptor: AccessTokenInterceptor(
                accountDataRepository: accountDataRepository,
                authApiClient: authApiClient,
                accountEventBus: accountEventBus
            ),
            jsonDecoder: jsonDecoder
        )
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

    func acceptTerms(_ userId: Int64, _ timestamp: Date) async -> Bool {
        let payload = NetworkAcceptTermsPayload(
            acceptedTerms: true,
            acceptedTermsTimestamp: dateFormatter.string(from: timestamp)
        )
        let request = requestProvider.acceptTerms
            .addPaths("\(userId)")
            .setBody(payload)
        let result = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkAccountProfileResult.self
        )
        return result.value?.hasAcceptedTerms == true
    }
}
