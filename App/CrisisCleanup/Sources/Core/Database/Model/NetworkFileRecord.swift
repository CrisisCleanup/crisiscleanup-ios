import Foundation
import GRDB

// TODO: Add equivalent database table(s). Write tests as necessary.
struct NetworkFileRecord : Identifiable, Equatable {
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

    fileprivate enum Columns: String, ColumnExpression {
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
}
