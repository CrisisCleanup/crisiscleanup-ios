import Foundation
import GRDB

struct NetworkFileRecord : Identifiable, Equatable {
    static let networkFileLocalImage = hasOne(NetworkFileLocalImageRecord.self)
    static let networkFileToWorksite = hasOne(WorksiteToNetworkFileRecord.self)

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

    static func deleteUnspecified(
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
            .filter(deleteIdSet.contains(Columns.id))
            .deleteAll(db)
    }
}

extension DerivableRequest<NetworkFileRecord> {
    func selectImageUrl() -> Self {
        select(NetworkFileRecord.Columns.fullUrl)
    }

    func selectFileId() -> Self {
        select(NetworkFileRecord.Columns.fileId)
    }

    func byWorksiteIdNotDeleted(
        _ fiAlias: TableAlias,
        _ wfAlias: TableAlias,
        _ worksiteId: Int64
    ) -> Self {
        filter(
            wfAlias[WorksiteToNetworkFileRecord.Columns.id] == worksiteId &&
            fiAlias[NetworkFileLocalImageRecord.Columns.isDeleted]
        )
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
        _ networkFileIds: Set<Int64>,
    ) throws {
        try WorksiteToNetworkFileRecord
            .filter(Columns.id == worksiteId && !networkFileIds.contains(Columns.networkFileId))
            .deleteAll(db)
    }

    static func deleteWorksiteNetworkFiles(
        _ db: Database,
        _ worksiteId: Int64,
    ) throws {
        try WorksiteToNetworkFileRecord
            .filter(Columns.id == worksiteId)
            .deleteAll(db)
    }

    static func getWorksiteFromFile(
        _ db: Database,
        _ fileRecordId: Int64
    ) throws -> Int64? {
        try WorksiteToNetworkFileRecord
            .select(Columns.id)
            .filter(Columns.networkFileId == fileRecordId)
            .asRequest(of: Int64.self)
            .fetchOne(db)
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

    static func updateRotation(
        _ db: Database,
        _ id: Int64,
        _ rotationDegrees: Int
    ) throws {
        try db.execute(
            sql:
                """
                UPDATE networkFileLocalImage
                SET rotateDegrees=:rotationDegrees
                WHERE id=:id
                """,
            arguments: [
                "id": id,
                "rotationDegrees": rotationDegrees,
            ]
        )
    }

    static func markForDelete(
        _ db: Database,
        _ id: Int64
    ) throws {
        try NetworkFileLocalImageRecord(id: id, isDeleted: true, rotateDegrees: 0)
            .upsert(db)
    }
}
