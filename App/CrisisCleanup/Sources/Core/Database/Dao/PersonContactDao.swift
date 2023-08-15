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

    func getContact(_ id: Int64) -> PopulatedPersonContactOrganization? {
        try! reader.read { db in
            try PersonContactRecord
                .all()
                .including(optional: PersonContactRecord.organization)
                .byId(id)
                .asRequest(of: PopulatedPersonContactOrganization.self)
                .fetchOne(db)
        }
    }

    func savePersons(
        _ contacts: [PersonContactRecord],
        _ personOrganizations: [OrganizationToPrimaryContactRecord]
    ) throws {
        var newContacts = [PersonContactRecord]()
        for record in contacts {
            if getContact(record.id) == nil {
                newContacts.append(record)
            }
        }

        try database.saveContacts(newContacts, personOrganizations)
    }
}

extension AppDatabase {
    fileprivate func trimIncidentOrganizationContacts() async throws {
        try await dbWriter.write { db in
            try PersonContactRecord.trim(db)
        }
    }

    fileprivate func saveContacts(
        _ contacts: [PersonContactRecord],
        _ personOrganizations: [OrganizationToPrimaryContactRecord]
    ) throws {
        try dbWriter.write { db in
            for record in contacts {
                try record.upsert(db)
            }
            for record in personOrganizations {
                try record.upsert(db)
            }
        }
    }
}
