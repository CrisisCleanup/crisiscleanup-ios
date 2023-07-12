import Foundation
import GRDB

struct NetworkFileRecord : Identifiable, Equatable {
    static let networkFileLocalImage = hasOne(NetworkFileLocalImageRecord.self)

    let id: Int64
    let createdAt: Date
    let fileId: Int64
    let fileTypeT: String
    let fullUrl: String?
    let largeThumbnailUrl: String?
    let mimeContentType: String
    let smallThumbnailUrl: String?
    let tag: String?
    let title: String?
    let url: String
}

extension NetworkFileRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "networkFile"

    internal enum Columns: String, ColumnExpression {
        case id,
             createdAt,
             fileId,
             fileTypeT,
             fullUrl,
             largeThumbnailUrl,
             mimeContentType,
             smallThumbnailUrl,
             tag,
             title,
             url
    }

    static func deleteDeleted(
        _ db: Database,
        _ worksiteId: Int64,
        _ keepIds: Set<Int64>
    ) throws {
        let worksiteFileIds = try WorksiteToNetworkFileRecord
            .all()
            .select(WorksiteToNetworkFileRecord.Columns.networkFileId)
            .filter(WorksiteToNetworkFileRecord.Columns.id == worksiteId)
            .asRequest(of: Int64.self)
            .fetchAll(db)

        let deleteIds = try NetworkFileLocalImageRecord
            .all()
            .select(NetworkFileLocalImageRecord.Columns.id)
            .filter(
                NetworkFileLocalImageRecord.Columns.isDeleted &&
                !keepIds.contains(NetworkFileLocalImageRecord.Columns.id) &&
                worksiteFileIds.contains(NetworkFileLocalImageRecord.Columns.id)
            )
            .asRequest(of: Int64.self)
            .fetchAll(db)

        let deleteIdSet = Set(deleteIds)
        try NetworkFileRecord
            .all()
            .filter(deleteIdSet.contains(Columns.id))
            .deleteAll(db)
    }
}

// MARK: Worksite to network file

struct WorksiteToNetworkFileRecord : Identifiable, Equatable {
    static let files = belongsTo(NetworkFileRecord.self)

    let id: Int64
    let networkFileId: Int64
}

extension WorksiteToNetworkFileRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "worksiteToNetworkFile"

    internal enum Columns: String, ColumnExpression {
        case id,
             networkFileId
    }

    static func deleteUnspecified(
        _ db: Database,
        _ worksiteId: Int64,
        _ ids: Set<Int64>
    ) throws {
        try WorksiteToNetworkFileRecord
            .filter(Columns.id == worksiteId && !ids.contains(Columns.networkFileId))
            .deleteAll(db)
    }
}

// MARK: Network file local image

struct NetworkFileLocalImageRecord : Identifiable, Equatable {
    let id: Int64
    let isDeleted: Bool
    let rotateDegrees: Int
}

extension NetworkFileLocalImageRecord: Codable, FetchableRecord, PersistableRecord {
    static let files = belongsTo(NetworkFileRecord.self)

    static var databaseTableName: String = "networkFileLocalImage"

    internal enum Columns: String, ColumnExpression {
        case id,
             isDeleted,
             rotateDegrees
    }
}
