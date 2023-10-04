import Atomics
import Foundation

class RegisterApiClient : CrisisCleanupRegisterApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    init(
        networkRequestProvider: NetworkRequestProvider,
        appEnv: AppEnv
    ) {
        networkClient = AFNetworkingClient(appEnv)
        requestProvider = networkRequestProvider
    }

    func registerOrgVolunteer(_ invite: InvitationRequest) async -> NetworkAcceptedInvitationRequest? {
        let payload = NetworkInvitationRequest(
            firstName: invite.firstName,
            lastName: invite.lastName,
            email: invite.emailAddress,
            title: invite.title,
            password1: invite.password,
            password2: invite.password,
            mobile: invite.mobile,
            requestedTo: invite.inviterEmailAddress,
            primaryLanguage: invite.languageId
        )
        let request = requestProvider.requestInvitation
            .setBody(payload)
        return await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkAcceptedInvitationRequest.self
        ).value
    }
}
