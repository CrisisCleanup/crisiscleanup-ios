import Combine

public protocol OrgVolunteerRepository {
    func requestInvitation(_ invite: InvitationRequest) async -> InvitationRequestResult?
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
}

public struct InvitationRequestResult {
    let organizationName: String
    let organizationRecipient: String
}
