import GRDB

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
    static var databaseTableName: String = "personContact"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             firstName,
             lastName,
             email,
             mobile
    }

    static func trim(_ db: Database) throws {
        try db.execute(
            sql:
                """
                DELETE FROM personContact
                WHERE id IN(
                    SELECT pc.id
                    FROM personContact pc
                    LEFT JOIN organizationToPrimaryContact o2pc
                    ON pc.id=o2pc.contactId
                    WHERE o2pc.contactId IS NULL
                )
                """
        )
    }
}
