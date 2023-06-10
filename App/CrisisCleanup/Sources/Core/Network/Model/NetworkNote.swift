import Foundation

public struct NetworkNote: Codable, Equatable {
    // Incoming network ID is always defined
    let id: Int64?
    // TODO: @Serializable(InstantSerializer::class)
    let createdAt: Data
    let isSurvivor: Bool
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case isSurvivor = "is_survivor"
        case note
    }
}

public struct NetworkNoteNote: Codable, Equatable {
    let note: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case note
        case createdAt = "created_at"
    }
}
