struct NetworkWorkTypeChangeRequest: Codable {
    let workTypes: [String]
    let reason: String

    enum CodingKeys: String, CodingKey {
        case workTypes = "work_types",
             reason = "requested_reason"
    }
}

struct NetworkWorkTypeChangeRelease: Codable {
    let workTypes: [String]
    let reason: String

    enum CodingKeys: String, CodingKey {
        case workTypes = "work_types",
             reason = "unclaim_reason"
    }
}
