public struct NetworkAccountProfileResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let approvedIncidents: Set<Int64>?
    let hasAcceptedTerms: Bool?
    let files: [NetworkFile]?
    let activeRoles: Set<Int>

    enum CodingKeys: String, CodingKey {
        case errors,
             approvedIncidents = "approved_incidents",
             hasAcceptedTerms = "accepted_terms",
             files,
             activeRoles = "active_roles"
    }
}
