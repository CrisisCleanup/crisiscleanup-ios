import Foundation

public struct NetworkType: Codable, Equatable {
    let id: Int64?
    let typeT: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case typeT = "type_t"
        case createdAt = "created_at"
    }
}

internal let networkTypeFavorite = NetworkType(
    id: nil,
    typeT: "favorite",
    createdAt: nil
)
