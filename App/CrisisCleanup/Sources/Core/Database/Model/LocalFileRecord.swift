import GRDB

struct WorksiteLocalImageRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

    let id: Int64?
    let worksiteId: Int64
    let localDocumentId: String
    let uri: String
    let tag: String
    let rotateDegrees: Int
}

extension WorksiteLocalImageRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "worksiteLocalImage"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             worksiteId,
             localDocumentId,
             uri,
             tag,
             rotateDegrees
    }

    static func updateLocalImageRotation(
        _ db: Database,
        _ id: Int64,
        _ rotationDegrees: Int
    ) throws {
        try db.execute(
            sql:
            """
            UPDATE OR IGNORE worksiteLocalImage
            SET rotateDegrees=:rotationDegrees
            WHERE id=:id
            """,
            arguments: [
                "id": id,
                "rotationDegrees": rotationDegrees,
            ]
        )
    }

    func insertOrUpdateTag(_ db: Database) throws {
        let inserted = try insertAndFetch(db, onConflict: .ignore)
        if inserted == nil {
            try db.execute(
                sql:
                    """
                    UPDATE worksiteLocalImage
                    SET tag=:tag
                    WHERE worksiteId=:worksiteId AND local_document_id=:localDocumentId
                    """,
                arguments: [
                    "worksiteId": worksiteId,
                    "localDocumentId": localDocumentId,
                    "tag": tag,
                ]
            )
        }
    }
}

fileprivate typealias LocalImageColumn = WorksiteLocalImageRecord.Columns

extension DerivableRequest<WorksiteLocalImageRecord> {
    func selectUriColumn() -> Self {
        select(LocalImageColumn.uri)
    }

    func selectDescriptionColumns() -> Self {
        select(
            LocalImageColumn.id,
            LocalImageColumn.uri,
            LocalImageColumn.tag
        )
    }

    func byWorksiteId(_ worksiteId: Int64) -> Self {
        filter(LocalImageColumn.worksiteId == worksiteId)
    }

    func getUploadImageCounts(_ countColumnName: String = "count") -> Self {
        select(
            LocalImageColumn.worksiteId,
            count(LocalImageColumn.id).forKey(countColumnName),
            min(LocalImageColumn.id).forKey("minId")
        )
        .group(LocalImageColumn.worksiteId)
        .order(SQL("minId").sqlExpression)
    }

    func selectFileName() -> Self {
        select(LocalImageColumn.localDocumentId)
    }
}
