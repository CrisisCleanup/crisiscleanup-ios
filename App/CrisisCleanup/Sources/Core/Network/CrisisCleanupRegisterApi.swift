public protocol CrisisCleanupRegisterApi {
    func registerOrgVolunteer(_ invite: InvitationRequest) async -> InvitationRequestResult?

    func getInvitationInfo(_ invite: UserPersistentInvite) async -> OrgUserInviteInfo?

    func getInvitationInfo(_ inviteCode: String) async -> OrgUserInviteInfo?

    func acceptOrgInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult

    func createPersistentInvitation(
        organizationId: Int64,
        userId: Int64
    ) async throws -> NetworkPersistentInvitation

    func acceptPersistentInvitation(_ invite: CodeInviteAccept) async -> JoinOrgResult

    func inviteToOrganization(_ emailAddress: String, _ organizationId: Int64?) async -> Bool

    func registerOrganization(
        referer: String,
        invite: IncidentOrganizationInviteInfo
    ) async -> Bool
}
