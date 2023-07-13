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
    public private(set) var databaseVersion: Int32 = 0

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

        let epoch0 = Date(timeIntervalSince1970: 0)

        migrator.registerMigration(
            "worksite",
            foreignKeyChecks: .immediate
        ) { db in
            try db.create(table: "worksiteRoot") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("syncUuid", .text)
                    .notNull()
                    .defaults(to: "")
                t.column("localModifiedAt", .date)
                    .notNull()
                    .defaults(to: epoch0)
                t.column("syncedAt", .date)
                    .notNull()
                    .defaults(to: epoch0)
                t.column("localGlobalUuid", .text)
                    .notNull()
                    .defaults(to: "")
                t.column("isLocalModified", .boolean)
                    .notNull()
                    .defaults(to: false)
                t.column("syncAttempt", .integer)
                    .notNull()
                    .defaults(to: 0)

                t.column("networkId", .integer)
                    .notNull()
                    .defaults(to: -1)
                t.column("incidentId", .integer)
                    .notNull()
                    .references("incident", onDelete: .cascade)
            }
            try db.create(
                indexOn: "worksiteRoot",
                columns: ["networkId", "localGlobalUuid"],
                options: .unique
            )
            try db.create(
                indexOn: "worksiteRoot",
                columns: ["incidentId", "localGlobalUuid"]
            )
            try db.create(
                indexOn: "worksiteRoot",
                columns: ["isLocalModified", "localModifiedAt"]
            )

            try db.create(table: "worksite") { t in
                t.primaryKey("id", .integer)
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("networkId", .integer)
                    .notNull()
                    .defaults(to: -1)
                t.column("incidentId", .integer)
                    .notNull()
                t.column("address", .text)
                    .notNull()
                t.column("autoContactFrequencyT", .text)
                t.column("caseNumber", .text)
                    .notNull()
                t.column("city", .text)
                    .notNull()
                t.column("county", .text)
                    .notNull()
                // This can be null if full data is queried without short
                t.column("createdAt", .date)
                t.column("email", .text)
                t.column("favoriteId", .integer)
                t.column("keyWorkTypeType", .text)
                    .notNull()
                t.column("keyWorkTypeOrgClaim", .integer)
                t.column("keyWorkTypeStatus", .text)
                    .notNull()
                t.column("latitude", .numeric)
                    .notNull()
                t.column("longitude", .numeric)
                    .notNull()
                t.column("name", .text)
                    .notNull()
                t.column("phone1", .text)
                t.column("phone2", .text)
                t.column("plusCode", .text)
                t.column("postalCode", .text)
                    .notNull()
                t.column("reportedBy", .integer)
                t.column("state", .text)
                    .notNull()
                t.column("svi", .numeric)
                t.column("what3Words", .text)
                t.column("updatedAt", .date)
                    .notNull()

                // TODO: Write tests throughout (model, data, edit feature)
                /**
                 * Is relevant when [WorksiteRootEntity.isLocalModified] otherwise ignore
                 */
                t.column("isLocalFavorite", .boolean)
                    .notNull()
            }
            try db.create(
                indexOn: "worksite",
                columns: ["incidentId", "networkId"]
            )
            try db.create(
                indexOn: "worksite",
                columns: ["networkId"]
            )
            try db.create(
                indexOn: "worksite",
                columns: ["incidentId", "latitude", "longitude"]
            )
            try db.create(
                indexOn: "worksite",
                columns: ["incidentId", "longitude", "latitude"]
            )
            try db.create(
                indexOn: "worksite",
                columns: ["incidentId", "svi"]
            )
            try db.create(
                indexOn: "worksite",
                columns: ["incidentId", "updatedAt"]
            )

            try db.create(table: "workType") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("networkId", .integer)
                    .notNull()
                    .defaults(to: -1)
                t.column("worksiteId", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("createdAt", .date)
                t.column("orgClaim", .integer)
                t.column("nextRecurAt", .date)
                t.column("phase", .integer)
                t.column("recur", .text)
                t.column("status", .text)
                    .notNull()
                t.column("workType", .text)
                    .notNull()
            }
            try db.create(
                indexOn: "workType",
                columns: ["worksiteId", "workType"],
                options: .unique
            )
            try db.create(
                indexOn: "workType",
                columns: ["worksiteId", "networkId"]
            )

            try db.create(table: "worksiteFormData") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("worksiteId", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("fieldKey", .text)
                    .notNull()
                t.column("isBoolValue", .boolean)
                    .notNull()
                t.column("valueString", .text)
                    .notNull()
                t.column("valueBool", .boolean)
                    .notNull()
            }
            try db.create(
                indexOn: "worksiteFormData",
                columns: ["worksiteId", "fieldKey"],
                options: .unique
            )

            try db.create(table: "worksiteFlag") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("networkId", .integer)
                    .notNull()
                    .defaults(to: -1)
                t.column("worksiteId", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("action", .text)
                t.column("createdAt", .date)
                    .notNull()
                t.column("isHighPriority", .boolean)
                    .defaults(to: false)
                t.column("notes", .text)
                t.column("reasonT", .text)
                    .notNull()
                t.column("requestedAction", .text)
            }
            try db.create(
                indexOn: "worksiteFlag",
                columns: ["worksiteId", "reasonT"],
                options: .unique
            )

            try db.create(table: "worksiteNote") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("localGlobalUuid", .text)
                    .notNull()
                    .defaults(to: "")
                t.column("networkId", .integer)
                    .notNull()
                    .defaults(to: -1)
                t.column("worksiteId", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("createdAt", .date)
                    .notNull()
                t.column("isSurvivor", .boolean)
                    .notNull()
                t.column("note", .text)
                    .notNull()
            }
            try db.create(
                indexOn: "worksiteNote",
                columns: ["worksiteId", "networkId", "localGlobalUuid"],
                options: .unique
            )
            try db.create(
                indexOn: "worksiteNote",
                columns: ["worksiteId", "createdAt"]
            )

            try db.create(table: "worksiteSyncStat") { t in
                // Incident ID
                t.primaryKey("id", .integer)
                    .references("incident", onDelete: .cascade)
                t.column("syncStart", .date)
                    .notNull()
                t.column("targetCount", .integer)
                    .notNull()
                t.column("pagedCount", .integer)
                    .notNull()
                t.column("successfulSync", .date)
                t.column("attemptedSync", .date)
                t.column("attemptedCounter", .integer)
                    .notNull()
                t.column("appBuildVersionCode", .integer)
                    .notNull()
            }
        }

        migrator.registerMigration(
            "work-type-status-recent-case",
            foreignKeyChecks: .immediate
        ) { db in
            try db.create(table: "workTypeStatus") { t in
                /// status
                t.primaryKey("id", .text)
                t.column("name", .text)
                    .notNull()
                t.column("listOrder", .integer)
                    .notNull()
                t.column("primaryState", .text)
                    .notNull()
            }
            try db.create(
                indexOn: "workTypeStatus",
                columns: ["listOrder"]
            )

            try db.create(table: "recentWorksite") { t in
                t.primaryKey("id", .integer)
                    .references("worksite", onDelete: .cascade)
                t.column("incidentId", .integer)
                    .notNull()
                t.column("viewedAt", .date)
                    .notNull()
            }
            try db.create(
                indexOn: "recentWorksite",
                columns: ["incidentId", "viewedAt"]
            )
        }

        migrator.registerMigration(
            "incident-organization-primary-contact",
            foreignKeyChecks: .immediate
        ) { db in
            try db.create(table: "incidentOrganization") { t in
                t.primaryKey("id", .integer)
                t.column("name", .text)
                    .notNull()
            }

            try db.create(table: "personContact") { t in
                t.primaryKey("id", .integer)
                t.column("firstName", .text)
                    .notNull()
                t.column("lastName", .text)
                    .notNull()
                t.column("email", .text)
                    .notNull()
                t.column("mobile", .text)
                    .notNull()
            }

            try db.create(table: "organizationToPrimaryContact") { t in
                /// Organization ID
                t.column("id", .integer)
                    .notNull()
                    .references("incidentOrganization", onDelete: .cascade)
                t.column("contactId", .integer)
                    .notNull()
                    .references("personContact", onDelete: .cascade)
                t.primaryKey(["id", "contactId"])
            }
            try db.create(
                indexOn: "organizationToPrimaryContact",
                columns: ["contactId", "id"]
            )

            try db.create(table: "organizationAffiliate") { t in
                /// Organization ID
                t.column("id", .integer)
                    .notNull()
                    .references("incidentOrganization", onDelete: .cascade)
                t.column("affiliateId", .integer)
                    .notNull()
                t.primaryKey(["id", "affiliateId"])
            }
            try db.create(
                indexOn: "organizationAffiliate",
                columns: ["affiliateId", "id"]
            )

            try db.create(table: "incidentOrganizationSyncStat") { t in
                /// Incident ID
                t.primaryKey("id", .integer)
                t.column("targetCount", .integer)
                    .notNull()
                t.column("successfulSync", .date)
                t.column("appBuildVersionCode", .integer)
                    .notNull()
            }
        }

        migrator.registerMigration(
            "worksite-change-sync-log",
            foreignKeyChecks: .immediate
        ) { db in
            try db.create(table: "worksiteChange") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("appVersion", .integer)
                    .notNull()
                t.column("organizationId", .integer)
                    .notNull()
                t.column("worksiteId", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("syncUuid", .text)
                    .notNull()
                t.column("changeModelVersion", .integer)
                    .notNull()
                t.column("changeData", .text)
                    .notNull()
                t.column("createdAt", .date)
                    .notNull()
                t.column("saveAttempt", .integer)
                    .notNull()
                t.column("archiveAction", .text)
                    .notNull()
                t.column("saveAttemptAt", .date)
                    .notNull()
            }
            try db.create(
                indexOn: "worksiteChange",
                columns: ["worksiteId", "createdAt"]
            )

            try db.create(table: "syncLog") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("logTime", .date)
                    .notNull()
                t.column("logType", .text)
                    .notNull()
                t.column("message", .text)
                    .notNull()
                t.column("details", .text)
                    .notNull()
            }
            try db.create(
                indexOn: "syncLog",
                columns: ["logTime"]
            )
        }

        migrator.registerMigration(
            "network-file-local-image",
            foreignKeyChecks: .immediate
        ) { db in
            try db.create(table: "networkFile") { t in
                t.primaryKey("id", .integer)
                t.column("createdAt", .date)
                    .notNull()
                t.column("fileId", .integer)
                    .notNull()
                t.column("fileTypeT", .text)
                    .notNull()
                t.column("fullUrl", .text)
                t.column("largeThumbnailUrl", .text)
                t.column("mimeContentType", .text)
                    .notNull()
                t.column("smallThumbnailUrl", .text)
                t.column("tag", .text)
                t.column("title", .text)
                t.column("url", .text)
                    .notNull()
            }

            try db.create(table: "worksiteToNetworkFile") { t in
                t.column("id", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("networkFileId", .integer)
                    .notNull()
                    .references("networkFile", onDelete: .cascade)
                t.primaryKey(["id", "networkFileId"])
            }
            try db.create(
                indexOn: "worksiteToNetworkFile",
                columns: ["networkFileId", "id"]
            )

            try db.create(table: "networkFileLocalImage") { t in
                t.primaryKey("id", .integer)
                    .references("networkFile", onDelete: .cascade)
                t.column("isDeleted", .boolean)
                    .notNull()
                t.column("rotateDegrees", .integer)
                    .notNull()
            }
            try db.create(
                indexOn: "networkFileLocalImage",
                columns: ["isDeleted"]
            )

            try db.create(table: "worksiteLocalImage") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("worksiteId", .integer)
                    .notNull()
                    .references("worksiteRoot", onDelete: .cascade)
                t.column("localDocumentId", .text)
                    .notNull()
                t.column("uri", .text)
                    .notNull()
                t.column("tag", .text)
                    .notNull()
                t.column("rotateDegrees", .integer)
                    .notNull()
            }
            try db.create(
                indexOn: "worksiteLocalImage",
                columns: ["worksiteId", "localDocumentId"],
                options: .unique
            )
        }

        // TODO: Add new indexes for worksite change

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
