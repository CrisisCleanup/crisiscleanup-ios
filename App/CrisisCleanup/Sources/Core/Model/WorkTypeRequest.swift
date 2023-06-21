import Foundation

struct WorkTypeRequest {
    let workType: String
    let byOrg: Int64
    let createdAt: Date
    let approvedAt: Date?
    let rejectedAt: Date?
    let approvedRejectedReason: String

    var hasNoResponse: Bool { approvedAt == nil && rejectedAt == nil }
}
