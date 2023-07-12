import GRDB

struct WorksiteLocalImageRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

    let id: Int64
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
}
