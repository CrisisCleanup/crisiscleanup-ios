public struct NetworkAccountProfileResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let approvedIncidents: Set<Int64>?
    let hasAcceptedTerms: Bool?
    let files: [NetworkFile]?
    let organization: NetworkOrganizationShort?
    let activeRoles: Set<Int>?
    let internalState: NetworkProfileInternalState?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        errors = try container.decodeIfPresent([NetworkCrisisCleanupApiError].self, forKey: .errors)
        approvedIncidents = try container.decodeIfPresent(Set<Int64>.self, forKey: .approvedIncidents)
        hasAcceptedTerms = try container.decodeIfPresent(Bool.self, forKey: .hasAcceptedTerms)
        files = try container.decodeIfPresent([NetworkFile].self, forKey: .files)
        organization = container.decodeNetworkOrganizationShort(.organization)
        activeRoles = try container.decodeIfPresent(Set<Int>.self, forKey: .activeRoles)
        internalState = try container.decodeIfPresent(NetworkProfileInternalState.self, forKey: .internalState)
    }

    enum CodingKeys: String, CodingKey {
        case errors,
             approvedIncidents = "approved_incidents",
             hasAcceptedTerms = "accepted_terms",
             files,
             organization,
             activeRoles = "active_roles",
             internalState = "internal_state"
    }
}

public struct NetworkProfileInternalState: Codable, Equatable {
    let incidentThresholdLookup: [String: NetworkIncidentClaimThreshold]

    enum CodingKeys: String, CodingKey {
        case incidentThresholdLookup = "incidents"
    }
}

public struct NetworkIncidentClaimThreshold: Codable, Equatable {
    let claimedCount: Int?
    let closedRatio: Float?

    enum CodingKeys: String, CodingKey {
        case claimedCount = "claimed_work_type_count",
             closedRatio = "claimed_work_type_closed_ratio"
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
