import GRDB

// TODO: Create database tables and related

struct PersonContactRecord: Identifiable, Equatable {
    let id: Int64
    let firstName: String
    let lastName: String
    let email: String
    let mobile: String

    func asExternalModel() -> PersonContact {
        PersonContact(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile
        )
    }
}

extension PersonContactRecord: Codable, FetchableRecord, PersistableRecord {
    fileprivate enum Columns: String, ColumnExpression {
        case id,
             firstName,
             lastName,
             email,
             mobile
    }
}
