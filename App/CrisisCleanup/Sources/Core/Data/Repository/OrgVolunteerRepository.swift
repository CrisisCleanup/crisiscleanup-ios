import Combine
import Foundation

public protocol OrgVolunteerRepository {
    func requestInvitation(_ invite: InvitationRequest) async -> InvitationRequestResult?
    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo?
    func acceptInvitation(_ invite: CodeInviteAccept) async -> Bool

    func getOrgInvite(orgId: Int64, inviterUserId: Int64) async -> JoinOrgInvite
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

    func acceptInvitation(_ invite: CodeInviteAccept) async -> Bool {
        // TODO: Handle cases where an invite was already sent to the user from the org
        await registerApi.acceptOrgInvitation(invite)
    }

    func getOrgInvite(orgId: Int64, inviterUserId: Int64) async -> JoinOrgInvite {
        do {
            let invite = try await registerApi.createPersistentInvitation(orgId: orgId, userId: inviterUserId)
            return JoinOrgInvite(token: invite.token, orgId: invite.objectId, expiresAt: invite.expiresAt)
        } catch {
            logger.logError(error)
        }

        return JoinOrgInvite(token: "", orgId: 0, expiresAt: Date(timeIntervalSince1970: 0))
    }
}

public struct InvitationRequestResult {
    let organizationName: String
    let organizationRecipient: String
}
