import Foundation

struct NetworkUser: Codable, Equatable {
    let id: Int64
    let firstName: String
    let lastName: String
    let organization: Int64
    let files: [NetworkFile]

    enum CodingKeys: String, CodingKey {
        case id,
             firstName = "first_name",
             lastName = "last_name",
             organization,
             files
    }
}

public struct NetworkUserProfile: Codable {
    let id: Int64
    let email: String
    let firstName: String
    let lastName: String
    let files: [NetworkFile]?
    let organization: NetworkOrganizationShort

    enum CodingKeys: String, CodingKey {
        case id,
             email,
             firstName = "first_name",
             lastName = "last_name",
             files,
             organization
    }

    var profilePicUrl: String? { files?.profilePictureUrl }
}
