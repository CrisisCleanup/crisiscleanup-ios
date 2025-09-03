import Foundation

class RegisterApiClient : CrisisCleanupRegisterApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    private let networkError: Error

    init(
        networkRequestProvider: NetworkRequestProvider,
        accountDataRepository: AccountDataRepository,
        authApiClient: CrisisCleanupAuthApi,
        accountEventBus: AccountEventBus,
        appEnv: AppEnv
    ) {
        networkClient = AFNetworkingClient(
            appEnv,
            interceptor: AccessTokenInterceptor(
                accountDataRepository: accountDataRepository,
                authApiClient: authApiClient,
                accountEventBus: accountEventBus
            )
        )
        requestProvider = networkRequestProvider

        networkError = GenericError("Network error")
    }

    func registerOrgVolunteer(_ invite: InvitationRequest) async -> InvitationRequestResult? {
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
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkAcceptedInvitationRequest.self
        )

        if let result = response.value {
            if let errors = result.errors {
                if errors.condenseMessages.contains("already have an account") == true {
                    return InvitationRequestResult(organizationName: "", organizationRecipient: "", isNewAccountRequest: false)
                }
            } else if let organization = result.requestedOrganization,
                      let requestedTo = result.requestedTo {
                return InvitationRequestResult(
                    organizationName: organization,
                    organizationRecipient: requestedTo,
                    isNewAccountRequest: true
                )
            }
        }

        // TODO: Be explicit in result
        return nil
    }

    private func getOrganizationName(_ orgId: Int64) async -> String {
        let orgRequest = requestProvider.noAuthOrganization
            .addPaths("\(orgId)")
        let result = await networkClient.callbackContinue(
            requestConvertible: orgRequest,
            type: NetworkOrganizationShort.self
        )
        return result.value?.name ?? ""
    }

    private func getUserDetails(_ userId: Int64) async -> UserDetails {
        let userRequest = requestProvider.noAuthUser
            .addPaths("\(userId)")
        var displayName = ""
        var avatarUrl: URL? = nil
        var orgName = ""
        if let userInfo = await networkClient.callbackContinue(
            requestConvertible: userRequest,
            type: NetworkUser.self
        ).value {
            displayName = "\(userInfo.firstName) \(userInfo.lastName)"
            if let avatarUrlString = userInfo.files.profilePictureUrl {
                avatarUrl = URL(string: avatarUrlString)
            }
            orgName = await getOrganizationName(userInfo.organization)
        }

        return UserDetails(
            displayName: displayName,
            organizationName: orgName,
            avatarUrl: avatarUrl
        )
    }

    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo? {
        let request = requestProvider.invitationInfo
            .addPaths(inviteCode)
        if let invitationInfo = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkInvitationInfoResult.self,
            wrapResponseKey: "invite"
        ).value?.invite {
            if invitationInfo.expiresAt.isPast {
                return ExpiredNetworkOrgInvite
            }

            let inviter = invitationInfo.inviter
            let userDetails = await getUserDetails(inviter.id)
            let orgId = invitationInfo.existingUser?.organization
            let orgName = orgId == nil ? "" : await getOrganizationName(orgId!)
            return OrgUserInviteInfo(
                displayName: "\(inviter.firstName) \(inviter.lastName)",
                inviterEmail: inviter.email,
                inviterAvatarUrl: userDetails.avatarUrl,
                invitedEmail: invitationInfo.inviteeEmail,
                orgName: userDetails.organizationName,
                expiration: invitationInfo.expiresAt,
                isExpiredInvite: false,
                isExistingUser: invitationInfo.isExistingUser,
                fromOrgName: orgName,
            )
        }

        return nil
    }

    func getInvitationInfo(_ invite: UserPersistentInvite) async -> OrgUserInviteInfo? {
        let request = requestProvider.persistentInvitationInfo
            .addPaths(invite.inviteToken)
        if let invitationInfo = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkPersistentInvitationResult.self,
            wrapResponseKey: "invite"
        ).value?.invite {
            if invitationInfo.expiresAt.isPast {
                return ExpiredNetworkOrgInvite
            }

            let userDetails = await getUserDetails(invite.inviterUserId)
            return OrgUserInviteInfo(
                displayName: userDetails.displayName,
                inviterEmail: "",
                inviterAvatarUrl: userDetails.avatarUrl,
                invitedEmail: "",
                orgName: userDetails.organizationName,
                expiration: invitationInfo.expiresAt,
                isExpiredInvite: false,
                isExistingUser: false,
                fromOrgName: "",
            )
        }

        return nil
    }

    func acceptOrgInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult {
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
        let request = requestProvider.acceptInvitationFromCode
            .setBody(payload)
        let isJoined = await networkClient.callbackContinue(
            requestConvertible: request,
            // TODO: Determine response type and what constitutes success?
            type: NetworkAcceptedCodeInvitationRequest.self
        ).value?.status == "invitation_accepted"
        return isJoined ? .success : .unknown
    }

    func createPersistentInvitation(
        organizationId: Int64,
        userId: Int64
    ) async throws -> NetworkPersistentInvitation {
        let request = requestProvider.createPersistentInvitation
            .setBody(NetworkCreateOrgInvitation(createdBy: userId, organizationId: organizationId))

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

    func acceptPersistentInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult {
        let payload = NetworkAcceptPersistentInvite(
            firstName: invite.firstName,
            lastName: invite.lastName,
            email: invite.emailAddress,
            title: invite.title,
            password: invite.password,
            mobile: invite.mobile,
            token: invite.invitationCode
        )
        let request = requestProvider.acceptPersistentInvitation
            .setBody(payload)
        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkAcceptedPersistentInvite.self
        ).value
        switch response?.detail {
        case "You have been added to the organization.":
            return .success
        case "User already a member of this organization.":
            return .redundant
        default:
            return .unknown
        }
    }

    func inviteToOrganization(_ emailAddress: String, _ organizationId: Int64?) async -> OrgInviteResult {
        let request = requestProvider.inviteToOrganization
            .setBody(NetworkOrganizationInvite(inviteeEmail: emailAddress, organization: organizationId))

        let result = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkOrganizationInviteInfo.self
        ).value
        if result?.inviteeEmail == emailAddress {
            return .invited
        }

        if result?.errors?.condenseMessages.contains("is already a part of this organization") == true {
            return .redundant
        }

        return .unknown
    }

    func registerOrganization(
        referer: String,
        invite: IncidentOrganizationInviteInfo
    ) async -> Bool {
        let request = requestProvider.registerOrganization
            .setBody(NetworkOrganizationRegistration(
                name: invite.organizationName,
                referral: referer,
                incident: invite.incidentId,
                contact: NetworkOrganizationContact(
                    email: invite.emailAddress,
                    firstName: invite.firstName,
                    lastName: invite.lastName,
                    mobile: invite.mobile,
                    title: nil,
                    organization: nil
                )
            ))

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkRegisterOrganizationResult.self,
            wrapResponseKey: "organization"
        )
        if let organization = response.value?.organization,
           organization.id > 0,
           organization.name.lowercased() == invite.organizationName.lowercased()
        {
            return true
        }
        return false
    }
}

private struct UserDetails {
    let displayName: String
    let organizationName: String
    let avatarUrl: URL?
}
