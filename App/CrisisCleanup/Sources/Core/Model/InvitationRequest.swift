public struct InvitationRequest: Equatable {
    let firstName: String
    let lastName: String
    let emailAddress: String
    let title: String
    let password: String
    let mobile: String
    let languageId: Int64

    let inviterEmailAddress: String
}

public struct InvitationRequestResult {
    let organizationName: String
    let organizationRecipient: String
    let isNewAccountRequest: Bool
}

public struct IncidentOrganizationInviteInfo {
    let incidentId: Int64
    let organizationName: String
    let emailAddress: String
    let mobile: String
    let firstName: String
    let lastName: String
}

public struct CodeInviteAccept: Equatable {
    let firstName: String
    let lastName: String
    let emailAddress: String
    let title: String
    let password: String
    let mobile: String
    let languageId: Int64

    let invitationCode: String
}

public enum OrgInviteResult {
    case invited,
         redundant,
         unknown
}
