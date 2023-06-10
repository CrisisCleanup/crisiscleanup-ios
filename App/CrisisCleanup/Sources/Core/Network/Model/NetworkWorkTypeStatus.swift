public struct NetworkWorkTypeStatusResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorkTypeStatusFull]?
}

public struct NetworkWorkTypeStatusFull: Codable, Equatable {
    let status: String
    let name: String
    let listOrder: Int
    let primaryState: String

    enum CodingKeys: String, CodingKey {
        case status
        case name = "status_name_t"
        case listOrder = "list_order"
        case primaryState = "primary_state"
    }
}
