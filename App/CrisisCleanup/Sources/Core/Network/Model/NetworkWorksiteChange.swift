import Foundation

public struct NetworkWorksiteChangeResult: Codable {
    let errors: [NetworkCrisisCleanupApiError]?
    let error: String?
    let changes: [NetworkWorksiteChange]?
}

public struct NetworkWorksiteChange: Codable {
    let incidentId: Int64
    let worksiteId: Int64
    let invalidatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case incidentId = "incident_id",
             worksiteId = "worksite_id",
             invalidatedAt = "invalidated_at"
    }
}
