public enum NavigationRoute: Identifiable, Hashable, Codable {
    case work,
         menu,
         searchCases,
         filterCases,
         viewCase(incidentId: Int64, worksiteId: Int64),
         createEditCase(incidentId: Int64, worksiteId: Int64?),
         caseSearchLocation,
         caseMoveOnMap,
         caseShare,
         caseShareStep2,
         caseFlags(_ isFromCaseEdit: Bool),
         caseHistory,
         caseWorkTypeTransfer,
         caseAddNote,
         viewImage(_ imageId: Int64, _ isNetworkImage: Bool, _ screenTitle: String),
         syncInsights,
         userFeedback,
         loginWithEmail,
         loginWithPhone,
         recoverPassword(
            showForgotPassword: Bool = false,
            showMagicLink: Bool = false
         ),
         resetPassword(_ recoverCode: String),
         volunteerOrg,
         requestOrgAccess,
         orgUserInvite(_ inviteCode: String),
         scanOrgQrCode,
         inviteTeammate,
         orgPersistentInvite(_ inviteToken: String)

    public var id: Int {
        switch self {
        case .work:         return 0
        case .menu:         return 1
        case .searchCases:  return 3
        case .filterCases:  return 4
        case .viewCase:     return 5
        case .createEditCase:       return 6
        case .caseShare:    return 7
        case .caseFlags:    return 8
        case .caseHistory:  return 9
        case .caseWorkTypeTransfer: return 10
        case .caseAddNote:  return 11
        case .viewImage:    return 12
        case .caseSearchLocation:   return 13
        case .caseMoveOnMap:return 14
        case .caseShareStep2:       return 15
        case .userFeedback: return 16
        case .loginWithEmail:       return 17
        case .loginWithPhone:       return 18
        case .recoverPassword:      return 19
        case .resetPassword:        return 20
        case .volunteerOrg:         return 21
        case .requestOrgAccess:     return 22
        case .orgUserInvite:        return 23
        case .scanOrgQrCode:        return 24
        case .inviteTeammate:       return 25
        case .orgPersistentInvite:  return 26

        case .syncInsights: return 77
        }
    }
}
