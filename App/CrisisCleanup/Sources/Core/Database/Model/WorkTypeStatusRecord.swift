import GRDB

struct WorkTypeStatusRecord : Identifiable, Equatable {
    let id: String
    let name: String
    let listOrder: Int
    let primaryState: String
}

extension WorkTypeStatusRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "workTypeStatus"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             name,
             listOrder,
             primaryState
    }
}

extension DerivableRequest<WorkTypeStatusRecord> {
    func orderedByListOrderDesc() -> Self {
        order(WorkTypeStatusRecord.Columns.listOrder.desc)
    }
}
