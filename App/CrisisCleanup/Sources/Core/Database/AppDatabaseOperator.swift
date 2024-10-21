import GRDB

class AppDatabaseOperator: DatabaseOperator {
    private let database: AppDatabase

    init(_ database: AppDatabase) {
        self.database = database
    }

    func clearBackendDataTables() throws {
        _ = try database.dbWriter.write { db in
            try IncidentRecord.deleteAll(db)
            try IncidentLocationRecord.deleteAll(db)
            try LocationRecord.deleteAll(db)
            try RecentWorksiteRecord.deleteAll(db)
            try IncidentOrganizationRecord.deleteAll(db)
            try PersonContactRecord.deleteAll(db)
            try IncidentOrganizationSyncStatRecord.deleteAll(db)
            try WorksiteChangeRecord.deleteAll(db)
            try SyncLogRecord.deleteAll(db)
            try NetworkFileRecord.deleteAll(db)
            try ListRecord.deleteAll(db)
        }

        try database.dbWriter.vacuum()
    }
}
