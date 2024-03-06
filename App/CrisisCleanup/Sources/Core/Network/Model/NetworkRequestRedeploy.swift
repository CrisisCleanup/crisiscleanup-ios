import Foundation

struct NetworkRequestRedeploy: Codable {
    let organization: Int64
    let incident: Int64
}

struct NetworkIncidentRedeployRequest: Codable {
    let id: Int64
    let organization: Int64
    let incident: Int64
    let createdAt: Date
    let organizationName: String
    let incidentName: String

    enum CodingKeys: String, CodingKey {
        case id,
             organization,
             incident = "object_id",
             createdAt = "created_at",
             organizationName = "organization_name",
             incidentName = "incident_name"
    }
}

struct NetworkRedeployRequestsResult: Codable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkIncidentRedeployRequest]?
}
