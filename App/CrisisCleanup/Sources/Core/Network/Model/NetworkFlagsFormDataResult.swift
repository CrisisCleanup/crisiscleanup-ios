struct NetworkFlagsFormDataResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkFlagsFormData]?
}

public struct NetworkFlagsFormData: Codable, Equatable {
    let id: Int64
    let caseNumber: String
    let formData: [KeyDynamicValuePair]
    let flags: [NetworkFlag]
    let phone1: String?
    let reportedBy: Int64

    enum CodingKeys: String, CodingKey {
        case id,
             caseNumber = "case_number",
             formData = "form_data",
             flags,
             phone1,
             reportedBy = "reported_by"
    }

    public struct NetworkFlag: Codable, Equatable {
        let isHighPriority: Bool?
        let reasonT: String?

        enum CodingKeys: String, CodingKey {
            case isHighPriority = "is_high_priority",
                 reasonT = "reason_t"
        }
    }
}
