import Foundation

let WorksiteChangeModelVersion = 4

struct WorkTypeTransfer: Codable {
    let reason: String
    let workTypes: [String]

    var hasValue: Bool { reason.isNotBlank && workTypes.isNotEmpty }
}

// sourcery: copyBuilder
struct WorksiteChange: Codable {
    // v4
    let isWorksiteDataChange: Bool?
    // v1
    let start: WorksiteSnapshot?
    let change: WorksiteSnapshot
    // v2
    let requestWorkTypes: WorkTypeTransfer?
    let releaseWorkTypes: WorkTypeTransfer?

    // v4
    var isWorkTypeTransferChange: Bool {
        requestWorkTypes?.hasValue == true || releaseWorkTypes?.hasValue == true
    }
}

struct SyncWorksiteChange {
    let id: Int64
    let createdAt: Date
    let syncUuid: String
    let isPartiallySynced: Bool
    let worksiteChange: WorksiteChange
}
