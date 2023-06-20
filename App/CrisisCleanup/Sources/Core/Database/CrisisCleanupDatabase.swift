import Foundation
import GRDB
import os.log

/// Create an `AppDatabase` with a connection to an SQLite database
/// (see <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections>).
///
/// Create those connections with a configuration returned from
/// `AppDatabase/makeConfiguration(_:)`.
///
/// For example:
///
/// ```swift
/// // Create an in-memory AppDatabase
/// let config = AppDatabase.makeConfiguration()
/// let dbQueue = try DatabaseQueue(configuration: config)
/// let appDatabase = try AppDatabase(dbQueue)
/// ```
public struct AppDatabase: DatabaseVersionProvider {
    private(set) var databaseVersion: Int32 = 0

    /// Creates an `AppDatabase`, and makes sure the database schema
    /// is ready.
    ///
    /// - important: Create the `DatabaseWriter` with a configuration
    ///   returned by ``makeConfiguration(_:)``.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try dbWriter.read { db in
            databaseVersion = try db.schemaVersion()
        }
        try migrator.migrate(dbWriter)
    }

    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections>
    internal let dbWriter: any DatabaseWriter
}

// MARK: - Database Configuration

extension AppDatabase {
    private static let sqlLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SQL")

    /// SQL statements are logged if the `SQL_TRACE` environment variable
    /// is set.
    ///
    /// - parameter base: A base configuration.
    public static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base

        // An opportunity to add required custom SQL functions or
        // collations, if needed:
        // config.prepareDatabase { db in
        //     db.add(function: ...)
        // }

        // Log SQL statements if the `SQL_TRACE` environment variable is set.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/database/trace(options:_:)>
        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace {
                    // It's ok to log statements publicly. Sensitive
                    // information (statement arguments) are not logged
                    // unless config.publicStatementArguments is set
                    // (see below).
                    os_log("%{public}@", log: sqlLogger, type: .debug, String(describing: $0))
                }
            }
        }

#if DEBUG
        // Protect sensitive information by enabling verbose debugging in
        // DEBUG builds only.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/configuration/publicstatementarguments>
        config.publicStatementArguments = true
#endif

        return config
    }
}

// MARK: - Database Migrations

extension AppDatabase {
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

#if DEBUG
        // Speed up development by nuking the database when migrations change
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
        migrator.eraseDatabaseOnSchemaChange = true
#endif

        /*
         * https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations
         * - Define the database schema with strings. No variables or string formatting.
         * - `foreignKeyChecks: .immediate` can be used when tables are not recreated for faster migration.
         * https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseschema
         * - Table names should be English, singular, and camelCased
         * - Column names should be camelCased
         * - Tables should have explicit primary keys
         * - Single-column primary keys should be named ‘id’
         * - Unique keys should be supported by unique indexes
         * - Relations between tables should be supported by foreign keys
         */
        migrator.registerMigration(
            "translation-incident-location-form-field",
            foreignKeyChecks: .immediate
        ) { db in
            try db.create(table: "languageTranslation") { t in
                t.primaryKey("key", .text)
                t.column("name", .text).notNull()
                t.column("translationJson", .text)
                t.column("syncedAt", .date).defaults(to: 0)
            }

            try db.create(table: "incident") { t in
                t.primaryKey("id", .integer)
                t.column("startAt", .date).notNull()
                t.column("name", .text).notNull()
                t.column("shortName", .text).notNull()
                t.column("type", .text).notNull()
                t.column("activePhoneNumber", .text)
                t.column("turnOnRelease", .boolean).notNull()
                t.column("isArchived", .boolean).notNull()
            }
            try db.create(
                indexOn: "incident",
                columns: ["startAt"]
            )

            try db.create(table: "incidentLocation") { t in
                // location.id
                t.primaryKey("id", .integer)
                // location.location
                t.column("location", .integer).notNull()
            }
            try db.create(table: "incidentToIncidentLocation") { t in
                // incident.id
                t.column("id", .integer)
                    .notNull()
                    .references("incident", onDelete: .cascade)
                // incidentLocation.id
                t.column("incidentLocationId", .integer)
                    .notNull()
                    .references("incidentLocation", onDelete: .cascade)
                t.primaryKey(["id", "incidentLocationId"])
            }
            try db.create(
                indexOn: "incidentToIncidentLocation",
                columns: ["incidentLocationId", "id"]
            )

            try db.create(table: "incidentFormField") { t in
                t.primaryKey("id", .integer)
                t.column("incidentId", .integer)
                    .notNull()
                    .references("incident", onDelete: .cascade)
                t.column("parentKey", .text).notNull()
                t.column("fieldKey", .text).notNull()
                t.column("label", .text).notNull()
                t.column("htmlType", .text).notNull()
                t.column("dataGroup", .text).notNull()
                t.column("help", .text)
                t.column("placeholder", .text)
                t.column("readOnlyBreakGlass", .boolean).notNull()
                t.column("valuesDefaultJson", .text)
                t.column("isCheckboxDefaultTrue", .boolean)
                t.column("orderLabel", .integer).notNull()
                t.column("validation", .text)
                t.column("recurDefault", .text)
                t.column("valuesJson", .text)
                t.column("isRequired", .boolean)
                t.column("isReadOnly", .boolean)
                t.column("listOrder", .integer).notNull()
                t.column("isInvalidated", .boolean).notNull()
                t.column("selectToggleWorkType", .text)
            }
            try db.create(
                indexOn: "incidentFormField",
                columns: ["incidentId", "parentKey", "fieldKey"],
                options: .unique
            )
            try db.create(
                indexOn: "incidentFormField",
                columns: ["incidentId", "isInvalidated", "dataGroup", "parentKey", "listOrder"]
            )

            try db.create(table: "location") { t in
                t.primaryKey("id", .integer)
                t.column("shapeType", .text).notNull()
                // Newline delimited sequences of
                //   comma delimited latitude,longitude coordinates
                t.column("coordinates", .text).notNull()
            }
        }

        return migrator
    }
}

// MARK: - Database Access: Reads

extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader {
        dbWriter
    }
}
