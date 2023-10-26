import Atomics
import Foundation

class RegisterApiClient : CrisisCleanupRegisterApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let networkError: Error

    init(
        networkRequestProvider: NetworkRequestProvider,
        accountDataRepository: AccountDataRepository,
        authApiClient: CrisisCleanupAuthApi,
        authEventBus: AuthEventBus,
        appEnv: AppEnv
    ) {
        networkClient = AFNetworkingClient(
            appEnv,
            interceptor: AccessTokenInterceptor(
                accountDataRepository: accountDataRepository,
                authApiClient: authApiClient,
                authEventBus: authEventBus
            )
        )
        requestProvider = networkRequestProvider

        networkError = GenericError("Network error")
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

    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo? {
        let request = requestProvider.invitationInfo
            .addPaths(inviteCode)
        if let invitationInfo = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkInvitationInfo.self
        ).value {
            if invitationInfo.expiresAt.isPast {
                return ExpiredNetworkOrgInvite
            }

            let inviter = invitationInfo.inviter
            let inviterId = inviter.id
            let userRequest = requestProvider.noAuthUser
                .addPaths("\(inviterId)")
            var avatarUrl: URL? = nil
            var orgName = ""
            if let userInfo = await networkClient.callbackContinue(
                requestConvertible: userRequest,
                type: NetworkUser.self
            ).value {
                if let avatarUrlString = userInfo.files.first(where: { $0.isProfilePicture })?.largeThumbnailUrl {
                    avatarUrl = URL(string: avatarUrlString)
                }
                orgName = userInfo.organization.name
            }
            return OrgUserInviteInfo(
                displayName: "\(inviter.firstName) \(inviter.lastName)",
                inviterEmail: inviter.email,
                inviterAvatarUrl: avatarUrl,
                invitedEmail: invitationInfo.inviteeEmail,
                orgName: orgName,
                isExpiredInvite: false
            )
        }

        return nil
    }

    func acceptOrgInvitation(_ invite: CodeInviteAccept) async -> Bool {
        let payload = NetworkAcceptCodeInvite(
            firstName: invite.firstName,
            lastName: invite.lastName,
            email: invite.emailAddress,
            title: invite.title,
            password: invite.password,
            mobile: invite.mobile,
            invitationToken: invite.invitationCode,
            primaryLanguage: invite.languageId
        )
        let request = requestProvider.requestInvitationFromCode
            .setBody(payload)
        return await networkClient.callbackContinue(
            requestConvertible: request,
            // TODO: Determine response type and what constitutes success?
            type: NetworkAcceptedInvitationRequest.self
        ).value != nil
    }

    func createPersistentInvitation(
        orgId: Int64,
        userId: Int64
    ) async throws -> NetworkPersistentInvitation {
        let request = requestProvider.createPersistentInvitation
            .setBody(NetworkCreateOrgInvitation(createdBy: userId, orgId: orgId))

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkPersistentInvitationResult.self,
            wrapResponseKey: "invite"
        )
        if let result = response.value?.invite {
            return result
        }
        throw response.error ?? networkError
    }
}
