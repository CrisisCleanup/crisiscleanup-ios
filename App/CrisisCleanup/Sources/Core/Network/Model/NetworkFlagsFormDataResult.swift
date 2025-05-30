import Foundation

public struct NetworkFlagsFormDataResult: Codable, Equatable, WorksiteDataResult {
    typealias T = NetworkFlagsFormData

    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkFlagsFormData]?

    var data: [NetworkFlagsFormData]? { results }
}

public struct NetworkFlagsFormData: Codable, Equatable, WorksiteDataSubset {
    let id: Int64
    let caseNumber: String
    let formData: [KeyDynamicValuePair]
    let flags: [NetworkFlag]
    let phone1: String?
    let reportedBy: Int64
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id,
             caseNumber = "case_number",
             formData = "form_data",
             flags,
             phone1,
             reportedBy = "reported_by",
             updatedAt = "updated_at"
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
