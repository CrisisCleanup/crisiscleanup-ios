struct NetworkAccountProfileResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let hasAcceptedTerms: Bool?
    let files: [NetworkFile]?

    enum CodingKeys: String, CodingKey {
        case errors,
             hasAcceptedTerms = "accepted_terms",
             files
    }
}
