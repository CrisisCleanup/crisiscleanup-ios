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
