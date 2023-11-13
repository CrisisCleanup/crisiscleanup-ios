import Combine
import Foundation

public protocol OrgVolunteerRepository {
    func requestInvitation(_ invite: InvitationRequest) async -> InvitationRequestResult?
    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo?
    func getInvitationInfo(_ invite: UserPersistentInvite) async -> OrgUserInviteInfo?
    func acceptInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult

    func getOrganizationInvite(organizationId: Int64, inviterUserId: Int64) async -> JoinOrgInvite
    func acceptPersistentInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult

    func inviteToOrganization(_ emailAddress: String, organizationId: Int64?) async -> Bool
}

extension OrgVolunteerRepository {
    func inviteToOrganization(_ emailAddress: String) async -> Bool {
        await inviteToOrganization(emailAddress, organizationId: nil)
    }
}

class CrisisCleanupOrgVolunteerRepository: OrgVolunteerRepository {
    private let registerApi: CrisisCleanupRegisterApi
    private let logger: AppLogger

    init(
        registerApi: CrisisCleanupRegisterApi,
        loggerFactory: AppLoggerFactory
    ) {
        self.registerApi = registerApi
        logger = loggerFactory.getLogger("org-volunteer")
    }

    func requestInvitation(_ invite: InvitationRequest) async -> InvitationRequestResult? {
        guard let result = await registerApi.registerOrgVolunteer(invite) else {
            // TODO: Handle cases where an invite was already sent to the user from the org
            return nil
        }

        return InvitationRequestResult(
            organizationName: result.requestedOrganization,
            organizationRecipient: result.requestedTo
        )
    }

    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo? {
        await registerApi.getInvitationInfo(inviteCode)
    }

    func getInvitationInfo(_ invite: UserPersistentInvite) async -> OrgUserInviteInfo? {
        await registerApi.getInvitationInfo(invite)
    }

    func acceptInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult {
        // TODO: Handle cases where an invite was already sent to the user from the org
        await registerApi.acceptOrgInvitation(invite)
    }

    func getOrganizationInvite(organizationId: Int64, inviterUserId: Int64) async -> JoinOrgInvite {
        do {
            let invite = try await registerApi.createPersistentInvitation(organizationId: organizationId, userId: inviterUserId)
            return JoinOrgInvite(token: invite.token, orgId: invite.objectId, expiresAt: invite.expiresAt)
        } catch {
            logger.logError(error)
        }

        return JoinOrgInvite(token: "", orgId: 0, expiresAt: Date(timeIntervalSince1970: 0))
    }

    func acceptPersistentInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult {
        await registerApi.acceptPersistentInvitation(invite)
    }

    func inviteToOrganization(_ emailAddress: String, organizationId: Int64?) async -> Bool {
        await registerApi.inviteToOrganization(emailAddress, organizationId)
    }
}

public struct InvitationRequestResult {
    let organizationName: String
    let organizationRecipient: String
}
