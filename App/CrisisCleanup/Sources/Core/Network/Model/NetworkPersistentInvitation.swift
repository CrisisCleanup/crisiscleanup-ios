import Foundation

public struct NetworkCreateOrgInvitation: Codable {
    let model: String = "organization_organizations"
    let createdBy: Int64
    let orgId: Int64

    enum CodingKeys: String, CodingKey {
        case model,
             createdBy = "created_by",
             orgId = "object_id"
    }
}

public struct NetworkPersistentInvitationResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let invite: NetworkPersistentInvitation?
}

public struct NetworkPersistentInvitation: Codable, Equatable {
    let id: Int64
    let token: String
    let model: String
    let objectId: Int64
    let requiresApproval: Bool
    let expiresAt: Date
    let createdAt: Date
    let updatedAt: Date
    let invalidatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id,
             token,
             model,
             objectId = "object_id",
             requiresApproval = "requires_approval",
             expiresAt = "expires_at",
             createdAt = "created_at",
             updatedAt = "updated_at",
             invalidatedAt = "invalidated_at"
    }
}
