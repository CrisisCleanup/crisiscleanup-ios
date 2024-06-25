import Foundation

public struct NetworkListsResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkList]?
}

public struct NetworkList: Codable, Equatable {
    let id: Int64
    let createdBy: Int64?
    let updatedBy: Int64?
    let createdAt: Date
    let updatedAt: Date
    let parent: Int64?
    let name: String
    let description: String?
    let listOrder: Int64?
    let tags: String?
    let model: String
    let objectIds: [Int64]?
    let shared: String
    let permissions: String
    let incident: Int64?
    let invalidateAt: Date?

    enum CodingKeys: String, CodingKey {
        case id,
             createdBy = "created_by",
             updatedBy = "updated_by",
             createdAt = "created_at",
             updatedAt = "updated_at",
             parent,
             name,
             description,
             listOrder = "list_order",
             tags,
             model,
             objectIds = "object_ids",
             shared,
             permissions,
             incident,
             invalidateAt = "invalidate_at"
    }
}

public struct NetworkListResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let list: NetworkList?
}
