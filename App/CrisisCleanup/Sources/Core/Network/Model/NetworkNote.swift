import Foundation

public struct NetworkNote: Codable, Equatable {
    // Incoming network ID is always defined
    let id: Int64?
    let createdAt: Date
    let isSurvivor: Bool
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case isSurvivor = "is_survivor"
        case note
    }

    init(
        _ id: Int64?,
        _ createdAt: Date,
        _ isSurvivor: Bool,
        _ note: String?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isSurvivor = isSurvivor
        self.note = note
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
