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
         caseFlags,
         caseHistory,
         caseWorkTypeTransfer,
         caseAddNote,
         viewImage(imageId: Int64)

    public var id: Int {
        switch self {
        case .work:         return 0
        case .menu:         return 1
        case .searchCases:  return 3
        case .filterCases:  return 4
        case .viewCase:     return 5
        case .createEditCase: return 6
        case .caseShare:    return 7
        case .caseFlags:    return 8
        case .caseHistory:  return 9
        case .caseWorkTypeTransfer: return 10
        case .caseAddNote:  return 11
        case .viewImage:    return 12
        case .caseSearchLocation: return 13
        case .caseMoveOnMap: return 14
        }
    }
}
