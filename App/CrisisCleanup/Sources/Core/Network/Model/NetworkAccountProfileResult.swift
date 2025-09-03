public struct NetworkAccountProfileResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let approvedIncidents: Set<Int64>?
    let hasAcceptedTerms: Bool?
    let files: [NetworkFile]?
    let organization: NetworkOrganizationShort?
    let activeRoles: Set<Int>?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.errors = try container.decodeIfPresent([NetworkCrisisCleanupApiError].self, forKey: .errors)
        self.approvedIncidents = try container.decodeIfPresent(Set<Int64>.self, forKey: .approvedIncidents)
        self.hasAcceptedTerms = try container.decodeIfPresent(Bool.self, forKey: .hasAcceptedTerms)
        self.files = try container.decodeIfPresent([NetworkFile].self, forKey: .files)
        self.organization = container.decodeNetworkOrganizationShort(.organization)
        self.activeRoles = try container.decodeIfPresent(Set<Int>.self, forKey: .activeRoles)
    }

    enum CodingKeys: String, CodingKey {
        case errors,
             approvedIncidents = "approved_incidents",
             hasAcceptedTerms = "accepted_terms",
             files,
             organization,
             activeRoles = "active_roles"
    }
}

extension KeyedDecodingContainer {
    func decodeNetworkOrganizationShort(_ key: KeyedDecodingContainer<Key>.Key) -> NetworkOrganizationShort? {
        if let id = try? decodeIfPresent(Int64.self, forKey: key) {
            return NetworkOrganizationShort(id, "")
        } else if let organization = try? decodeIfPresent(NetworkOrganizationShort.self, forKey: key) {
            return organization
        }
        return nil
    }
}
