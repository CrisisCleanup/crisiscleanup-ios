import Foundation
import GRDB

// sourcery: copyBuilder
struct ListRecord: Identifiable, Equatable {
    static let incident = belongsTo(IncidentRecord.self)

    var id: Int64?
    let networkId: Int64
    let localGlobalUuid: String
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
    let objectIds: String
    let shared: String
    let permissions: String
    let incidentId: Int64?
}

extension ListRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "list"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             networkId,
             localGlobalUuid,
             createdBy,
             updatedBy,
             createdAt,
             updatedAt,
             parent,
             name,
             description,
             listOrder,
             tags,
             model,
             objectIds,
             shared,
             permissions,
             incidentId
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func deleteByNetworkIds(
        _ db: Database,
        _ networkIds: Set<Int64>
    ) throws {
        try ListRecord
            .filter(networkIds.contains(Columns.networkId))
            .deleteAll(db)
    }

    func syncUpsert(_ db: Database) throws {
        let inserted = try insertAndFetch(db, onConflict: .ignore)
        if inserted == nil {
            try db.execute(
                sql:
                    """
                    UPDATE list SET
                    updatedBy   =:updatedBy,
                    updatedAt   =:updatedAt,
                    parent      =:parent,
                    name        =:name,
                    description =:description,
                    listOrder   =:listOrder,
                    tags        =:tags,
                    model       =:model,
                    objectIds   =:objectIds,
                    shared      =:shared,
                    permissions =:permissions,
                    incidentId  =:incidentId
                    WHERE networkId=:networkId AND localGlobalUuid=''
                    """,
                arguments: [
                    "updatedBy" : updatedBy,
                    "updatedAt" : updatedAt,
                    "parent"    : parent,
                    "name"      : name,
                    "description"   : description ?? "",
                    "listOrder"     : listOrder,
                    "tags"          : tags ?? "",
                    "model"         : model,
                    "objectIds"     : objectIds,
                    "shared"        : shared,
                    "permissions"   : permissions,
                    "incidentId"    : incidentId,
                    "networkId"     : networkId
                ]
            )
        }
    }
}

extension DerivableRequest<ListRecord> {
    func byIncident(_ incidentId: Int64) -> Self {
        filter(ListRecord.Columns.incidentId == incidentId)
    }

    func orderByUpdatedAtDesc() -> Self {
        order(ListRecord.Columns.updatedAt.desc)
    }

    func filterByNetworkIds(_ networkIds: Set<Int64>) -> Self {
        filter(networkIds.contains(ListRecord.Columns.networkId))
    }
}
