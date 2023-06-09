import Foundation

public struct NetworkWorkType: Codable, Equatable {
    // Incoming network ID is always defined
    let id: Int64?
    let createdAt: Date?
    let orgClaim: Int64?
    let nextRecurAt: Date?
    let phase: Int?
    let recur: String?
    let status: String
    let workType: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case orgClaim = "claimed_by"
        case nextRecurAt = "next_recur_at"
        case phase
        case recur
        case status
        case workType = "work_type"
    }
}

public struct NetworkWorkTypeStatus: Codable, Equatable {
    let status: String
}

public struct NetworkWorkTypeTypes: Codable, Equatable {
    let workTypes: [String]

    enum CodingKeys: String, CodingKey {
        case workTypes = "work_types"
    }
}
