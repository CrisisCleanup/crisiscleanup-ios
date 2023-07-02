enum NavigationRoute: Identifiable, Hashable {
    case work,
         menu,
         authenticate,
         searchCases,
         filterCases,
         viewCase(incidentId: Int64, worksiteId: Int64),
         createEditCase(incidentId: Int64, worksiteId: Int64)

    var id: Int {
        switch self {
        case .work: return 0
        case .menu: return 1
        case .authenticate: return 2
        case .searchCases: return 3
        case .filterCases: return 4
        case .viewCase: return 5
        case .createEditCase: return 6
        }
    }
}
