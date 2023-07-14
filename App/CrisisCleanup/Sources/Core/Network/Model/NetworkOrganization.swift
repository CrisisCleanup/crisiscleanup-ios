public struct NetworkOrganizationsResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkIncidentOrganization]?
}

public struct NetworkIncidentOrganization: Codable, Equatable {
    let id: Int64
    let name: String
    let affiliates: [Int64]
    let primaryLocation: Int64?
    let typeT: String?
    let primaryContacts: [NetworkPersonContact]?

    enum CodingKeys: String, CodingKey {
        case id,
             name,
             affiliates,
             primaryLocation = "primary_location",
             typeT = "type_t",
             primaryContacts = "primary_contacts"
    }
}

public struct NetworkOrganizationShort: Codable, Equatable {
    let id: Int64
    let name: String

    init(
        _ id: Int64,
        _ name: String
    ) {
        self.id = id
        self.name = name
    }
}
