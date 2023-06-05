import Foundation

public struct NetworkWorkTypeRequestResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorkTypeRequest]?
}

public struct NetworkWorkTypeRequest: Codable, Equatable {
    let id: Int64
    let workType: NetworkWorkType
    let requestedBy: Int64
    let approvedAt: Date?
    let rejectedAt: Date?
    let tokenExpiration: Date
    let createdAt: Date
    let acceptedRejectedReason: String?
    let byOrg: NetworkOrganizationShort
    let toOrg: NetworkOrganizationShort
    let worksite: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case workType = "worksite_work_type"
        case requestedBy = "requested_by"
        case approvedAt = "approved_at"
        case rejectedAt = "rejected_at"
        case tokenExpiration = "token_expiration"
        case createdAt = "created_at"
        case acceptedRejectedReason = "accepted_rejected_reason"
        case byOrg = "requested_by_org"
        case toOrg = "requested_to_org"
        case worksite
    }
}
