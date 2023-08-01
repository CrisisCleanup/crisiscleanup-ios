public struct NetworkUsersResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkPersonContact]?
}

public struct NetworkPersonContact: Codable, Equatable {
    let id: Int64
    let firstName: String
    let lastName: String
    let email: String
    let mobile: String
    // Provided from /users.
    // Not provided from /organizations
    let organization: ContactOrganization?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case mobile
        case organization
    }

    public struct ContactOrganization: Codable, Equatable {
        let id: Int64
        let name: String
        let affiliates: [Int64]
        let typeT: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case affiliates
            case typeT = "type_t"
        }
    }
}
