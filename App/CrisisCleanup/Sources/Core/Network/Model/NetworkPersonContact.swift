public struct NetworkPersonContact: Codable, Equatable {
    let id: Int64
    let firstName: String
    let lastName: String
    let email: String
    let mobile: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case mobile
    }
}
