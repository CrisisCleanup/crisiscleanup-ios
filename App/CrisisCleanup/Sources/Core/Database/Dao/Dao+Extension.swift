import GRDB

extension AppDatabase {
    func rebuildFtsTable(_ tableName: String) throws {
        try dbWriter.write { db in
            try db.execute(sql: "INSERT INTO \(tableName)(\(tableName)) VALUES('rebuild')")
        }
    }
}
