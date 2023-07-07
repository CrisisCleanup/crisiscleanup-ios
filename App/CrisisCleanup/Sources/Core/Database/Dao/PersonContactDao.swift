import GRDB

public class PersonContactDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func trimIncidentOrganizationContacts() async throws {
        try await database.trimIncidentOrganizationContacts()
    }
}

extension AppDatabase {
    fileprivate func trimIncidentOrganizationContacts() async throws {
        try await dbWriter.write { db in
            try PersonContactRecord.trim(db)
        }
    }
}
