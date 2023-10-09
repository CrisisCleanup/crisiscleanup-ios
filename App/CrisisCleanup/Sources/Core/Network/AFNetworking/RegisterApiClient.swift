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

    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo? {
        let request = requestProvider.invitationInfo
            .addPaths(inviteCode)
        if let invitationInfo = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkInvitationInfo.self
        ).value {
            if invitationInfo.expiresAt < Date.now {
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
}
