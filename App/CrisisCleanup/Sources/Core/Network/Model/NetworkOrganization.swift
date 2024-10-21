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
    let secondaryLocation: Int64?
    let typeT: String?
    let primaryContacts: [NetworkPersonContact]?

    enum CodingKeys: String, CodingKey {
        case id,
             name,
             affiliates,
             primaryLocation = "primary_location",
             secondaryLocation = "secondary_location",
             typeT = "type_t",
             primaryContacts = "primary_contacts"
    }
}

public struct NetworkOrganizationShort: Codable, Equatable {
    let id: Int64
    let name: String
    let isActive: Bool?

    init(
        _ id: Int64,
        _ name: String,
        _ isActive: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.isActive = isActive
    }

    enum CodingKeys: String, CodingKey {
        case id,
             name,
             isActive = "is_active"
    }
}

public struct NetworkOrganizationsSearchResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkOrganizationShort]?
}

struct NetworkRegisterOrganizationResult: Codable {
    let errors: [NetworkCrisisCleanupApiError]?
    let organization: NetworkOrganizationShort
}

struct NetworkOrganizationRegistration: Codable {
    let name: String
    let referral: String
    let incident: Int64
    let contact: NetworkOrganizationContact
}

struct NetworkOrganizationContact: Codable {
    let email: String
    let firstName: String
    let lastName: String
    let mobile: String
    let title: String?
    let organization: Int64?

    enum CodingKeys: String, CodingKey {
        case email,
             firstName = "first_name",
             lastName = "last_name",
             mobile,
             title,
             organization
    }
}
