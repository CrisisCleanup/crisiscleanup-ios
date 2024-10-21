public struct NetworkAccountProfileResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let approvedIncidents: Set<Int64>?
    let hasAcceptedTerms: Bool?
    let files: [NetworkFile]?
    let organization: NetworkOrganizationShort
    let activeRoles: Set<Int>

    enum CodingKeys: String, CodingKey {
        case errors,
             approvedIncidents = "approved_incidents",
             hasAcceptedTerms = "accepted_terms",
             files,
             organization,
             activeRoles = "active_roles"
    }
}
