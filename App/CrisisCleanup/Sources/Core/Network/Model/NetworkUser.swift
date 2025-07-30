import Foundation

struct NetworkUser: Codable, Equatable {
    let id: Int64
    let firstName: String
    let lastName: String
    let hasAcceptedTerms: Bool?
    let organization: Int64
    let files: [NetworkFile]

    enum CodingKeys: String, CodingKey {
        case id,
             firstName = "first_name",
             lastName = "last_name",
             hasAcceptedTerms = "accepted_terms",
             organization,
             files
    }
}

public struct NetworkUserProfile: Codable {
    let id: Int64
    let email: String
    let mobile: String
    let firstName: String
    let lastName: String
    let approvedIncidents: Set<Int64>
    let hasAcceptedTerms: Bool?
    let acceptedTermsTimestamp: Date?
    let files: [NetworkFile]?
    let organization: NetworkOrganizationShort
    let activeRoles: Set<Int>

    enum CodingKeys: String, CodingKey {
        case id,
             email,
             mobile,
             firstName = "first_name",
             lastName = "last_name",
             approvedIncidents = "approved_incidents",
             hasAcceptedTerms = "accepted_terms",
             acceptedTermsTimestamp = "accepted_terms_timestamp",
             files,
             organization,
             activeRoles = "active_roles"
    }

    var profilePicUrl: String? { files?.profilePictureUrl }
}
