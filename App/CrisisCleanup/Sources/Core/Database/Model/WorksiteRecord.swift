import Foundation
import GRDB

private let epoch0 = Date(timeIntervalSince1970: 0)

struct WorksiteRootRecord : Identifiable, Equatable {
    static let worksite = hasOne(WorksiteRecord.self)
    static let worksiteFlags = hasMany(WorksiteFlagRecord.self)
    static let worksiteFormData = hasMany(WorksiteFormDataRecord.self)
    static let worksiteNotes = hasMany(WorksiteNoteRecord.self)
    static let workTypes = hasMany(WorkTypeRecord.self)

    private static func newRecord(
        syncedAt: Date,
        networkId: Int64,
        incidentId: Int64
    ) -> WorksiteRootRecord {
        WorksiteRootRecord(
            id: nil,
            syncUuid: "",
            localModifiedAt: epoch0,
            syncedAt: epoch0,
            localGlobalUuid: "",
            isLocalModified: false,
            syncAttempt: 0,

            networkId: networkId,
            incidentId: incidentId
        )
    }

    var id: Int64?
    let syncUuid: String
    let localModifiedAt: Date
    let syncedAt: Date
    let localGlobalUuid: String
    let isLocalModified: Bool
    let syncAttempt: Int64

    let networkId: Int64
    let incidentId: Int64
}

extension WorksiteRootRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksiteRoot"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             syncUuid,
             localModifiedAt,
             syncedAt,
             localGlobalUuid,
             isLocalModified,
             syncAttempt,
             networkId,
             incidentId
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func insertOrRollback(
        _ db: Database,
        _ syncedAt: Date,
        _ networkId: Int64,
        _ incidentId: Int64
    ) throws -> Int64 {
        let rootRecord = WorksiteRootRecord.newRecord(
            syncedAt: syncedAt,
            networkId: networkId,
            incidentId: incidentId
        )
        return try rootRecord.insertAndFetch(db, onConflict: .rollback)!.id!
    }

    static func syncUpdate(
        _ db: Database,
        id: Int64,
        expectedLocalModifiedAt: Date,
        syncedAt: Date,
        networkId: Int64,
        incidentId: Int64
    ) throws {
        let record = try WorksiteRootRecord
            .all()
            .filter(Columns.id == id && Columns.networkId == networkId && Columns.localModifiedAt == expectedLocalModifiedAt)
            .fetchOne(db)
        if record == nil {
            throw GenericError("Worksite has been changed since local modified state was fetched")
        }

        try db.execute(
            sql:
                """
                UPDATE OR ROLLBACK worksiteRoot
                SET syncedAt=:syncedAt,
                    syncAttempt=0,
                    isLocalModified=0,
                    incidentId=:incidentId
                WHERE id=:id AND
                      networkId=:networkId AND
                      localModifiedAt=:expectedLocalModifiedAt
                """,
            arguments: [
                Columns.id.rawValue: id,
                "expectedLocalModifiedAt": expectedLocalModifiedAt,
                Columns.syncedAt.rawValue: syncedAt,
                Columns.networkId.rawValue: networkId,
                Columns.incidentId.rawValue: incidentId,
            ]
        )
    }

    static func getCount(_ db: Database, _ incidentId: Int64) throws -> Int {
        try WorksiteRootRecord
            .filter(Columns.incidentId == incidentId)
            .fetchCount(db)
    }

    static func getWorksiteId(_ db: Database, _ networkId: Int64) throws -> Int64 {
        let record = try WorksiteRootRecord
            .all()
            .filter(Columns.networkId == networkId && Columns.localGlobalUuid == "")
            .fetchOne(db)
        return record?.id ?? 0
    }
}

extension DerivableRequest<WorksiteRootRecord> {
    func byUnique(
        _ networkId: Int64,
        _ localGlobalUuid: String = ""
    ) -> Self {
        filter(
            RootColumns.networkId == networkId &&
            RootColumns.localGlobalUuid == localGlobalUuid
        )
    }

    func networkIdsIn(_ ids: Set<Int64>) -> Self {
        filter(ids.contains(WorksiteRootRecord.Columns.networkId))
    }

    func orderedByLocalModifiedAtDesc() -> Self {
        order(WorksiteRootRecord.Columns.localModifiedAt.desc)
    }

    func byIncidentId(_ id: Int64) -> Self {
        filter(RootColumns.incidentId == id)
    }
}

fileprivate typealias RootColumns = WorksiteRootRecord.Columns

// sourcery: copyBuilder
struct WorksiteRecord : Identifiable, Equatable {
    static let root = belongsTo(WorksiteRootRecord.self)

    var id: Int64?
    let networkId: Int64
    let incidentId: Int64
    let address: String
    let autoContactFrequencyT: String?
    let caseNumber: String
    let city: String
    let county: String
    // This can be null if full data is queried without short
    let createdAt: Date?
    let email: String?
    let favoriteId: Int64?
    let keyWorkTypeType: String
    let keyWorkTypeOrgClaim: Int64?
    let keyWorkTypeStatus: String
    let latitude: Double
    let longitude: Double
    let name: String
    let phone1: String?
    let phone2: String?
    let plusCode: String?
    let postalCode: String
    let reportedBy: Int64?
    let state: String
    let svi: Double?
    let what3Words: String?
    let updatedAt: Date

    // TODO: Write tests throughout (model, data, edit feature)
    /**
     * Is relevant when [WorksiteRootEntity.isLocalModified] otherwise ignore
     */
    let isLocalFavorite: Bool
}

extension WorksiteRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksite"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             networkId,
             incidentId,
             address,
             autoContactFrequencyT,
             caseNumber,
             city,
             county,
             // This can be null if full data is queried without short
             createdAt,
             email,
             favoriteId,
             keyWorkTypeType,
             keyWorkTypeOrgClaim,
             keyWorkTypeStatus,
             latitude,
             longitude,
             name,
             phone1,
             phone2,
             plusCode,
             postalCode,
             reportedBy,
             state,
             svi,
             what3Words,
             updatedAt
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    func syncUpdateWorksite(_ db: Database) throws {
        try db.execute(
            sql:
                """
                UPDATE OR ROLLBACK worksite
                SET
                incidentId          =:incidentId,
                address             =:address,
                autoContactFrequencyT=COALESCE(:autoContactFrequencyT,autoContactFrequencyT),
                caseNumber     	    =:caseNumber,
                city                =:city,
                county              =:county,
                createdAt           =COALESCE(:createdAt, createdAt),
                email               =COALESCE(:email, email),
                favoriteId          =:favoriteId,
                keyWorkTypeType     =CASE WHEN :keyWorkTypeType=='' THEN keyWorkTypeType ELSE :keyWorkTypeType END,
                keyWorkTypeOrgClaim =CASE WHEN :keyWorkTypeOrgClaim<0 THEN keyWorkTypeOrgClaim ELSE :keyWorkTypeOrgClaim END,
                keyWorkTypeStatus   =CASE WHEN :keyWorkTypeStatus=='' THEN keyWorkTypeStatus ELSE :keyWorkTypeStatus END,
                latitude    =:latitude,
                longitude   =:longitude,
                name        =:name,
                phone1      =COALESCE(:phone1, phone1),
                phone2      =COALESCE(:phone2, phone2),
                plusCode    =COALESCE(:plusCode, plusCode),
                postalCode  =:postalCode,
                reportedBy  =COALESCE(:reportedBy, reportedBy),
                state       =:state,
                svi         =:svi,
                what3Words  =COALESCE(:what3Words, what3Words),
                updatedAt   =:updatedAt
                WHERE id=:id AND networkId=:networkId
                """,
            arguments: [
                Columns.id.rawValue: id,
                Columns.networkId.rawValue: networkId,
                Columns.incidentId.rawValue: incidentId,
                Columns.address.rawValue: address,
                Columns.autoContactFrequencyT.rawValue: autoContactFrequencyT,
                Columns.caseNumber.rawValue: caseNumber,
                Columns.city.rawValue: city,
                Columns.county.rawValue: county,
                Columns.createdAt.rawValue: createdAt,
                Columns.email.rawValue: email,
                Columns.favoriteId.rawValue: favoriteId,
                Columns.keyWorkTypeType.rawValue: keyWorkTypeType,
                Columns.keyWorkTypeOrgClaim.rawValue: keyWorkTypeOrgClaim,
                Columns.keyWorkTypeStatus.rawValue: keyWorkTypeStatus,
                Columns.latitude.rawValue: latitude,
                Columns.longitude.rawValue: longitude,
                Columns.name.rawValue: name,
                Columns.phone1.rawValue: phone1,
                Columns.phone2.rawValue: phone2,
                Columns.plusCode.rawValue: plusCode,
                Columns.postalCode.rawValue: postalCode,
                Columns.reportedBy.rawValue: reportedBy,
                Columns.state.rawValue: state,
                Columns.svi.rawValue: svi,
                Columns.what3Words.rawValue: what3Words,
                Columns.updatedAt.rawValue: updatedAt,
            ]
        )
    }

    static func syncFillWorksite(
        _ db: Database,
        _ id: Int64,
        autoContactFrequencyT: String?,
        caseNumber: String,
        email: String?,
        favoriteId: Int64?,
        phone1: String?,
        phone2: String?,
        plusCode: String?,
        svi: Double?,
        reportedBy: Int64?,
        what3Words: String?
    ) throws {
        try db.execute(
            sql:
                """
                UPDATE OR ROLLBACK worksite
                SET
                autoContactFrequencyT=COALESCE(autoContactFrequencyT, :autoContactFrequencyT),
                caseNumber  =CASE WHEN LENGTH(caseNumber)==0 THEN :caseNumber ELSE caseNumber END,
                email       =COALESCE(email, :email),
                favoriteId  =COALESCE(favoriteId, :favoriteId),
                phone1      =CASE WHEN LENGTH(COALESCE(phone1,''))<2 THEN :phone1 ELSE phone1 END,
                phone2      =COALESCE(phone2, :phone2),
                plusCode    =COALESCE(plusCode, :plusCode),
                reportedBy  =COALESCE(reportedBy, :reportedBy),
                svi         =COALESCE(svi, :svi),
                what3Words  =COALESCE(what3Words, :what3Words)
                WHERE id=:id
                """,
            arguments: [
                Columns.id.rawValue: id,
                Columns.autoContactFrequencyT.rawValue: autoContactFrequencyT,
                Columns.caseNumber.rawValue: caseNumber,
                Columns.email.rawValue: email,
                Columns.favoriteId.rawValue: favoriteId,
                Columns.phone1.rawValue: phone1,
                Columns.phone2.rawValue: phone2,
                Columns.plusCode.rawValue: plusCode,
                Columns.reportedBy.rawValue: reportedBy,
                Columns.svi.rawValue: svi,
                Columns.what3Words.rawValue: what3Words,
            ])
    }

    static func getWorksiteId(
        _ db: Database,
        _ networkId: Int64
    ) throws -> Int64? {
        try WorksiteRecord.all()
            .filter(Columns.networkId == networkId)
            .fetchAll(db)
            .first!
            .id
    }

    static func getCount(
        _ db: Database,
        _ incidentId: Int64,
        south: Double,
        north: Double,
        west: Double,
        east: Double
    ) throws -> Int {
        try WorksiteRecord
            .filter(
                Columns.incidentId == incidentId &&
                Columns.longitude > west &&
                Columns.longitude < east &&
                Columns.latitude < north &&
                Columns.latitude > south
            )
            .fetchCount(db)
    }
}

extension DerivableRequest<WorksiteRecord> {
    func orderByUpdatedAtDescIdDesc() -> Self {
        order(
            WorksiteRecord.Columns.updatedAt.desc,
            WorksiteRecord.Columns.id.desc
        )
    }
}

// MARK: - Work type

// sourcery: copyBuilder
struct WorkTypeRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

    var id: Int64?
    let networkId: Int64
    let worksiteId: Int64
    let createdAt: Date?
    let orgClaim: Int64?
    let nextRecurAt: Date?
    let phase: Int?
    let recur: String?
    let status: String
    let workType: String

    func asExternalModel() -> WorkType {
        WorkType(
            id: id!,
            createdAt: createdAt,
            orgClaim: orgClaim,
            nextRecurAt: nextRecurAt,
            phase: phase,
            recur: recur,
            statusLiteral: status,
            workTypeLiteral: workType
        )
    }
}

extension WorkTypeRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "workType"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             networkId,
             worksiteId,
             createdAt,
             orgClaim,
             nextRecurAt,
             phase,
             recur,
             status,
             workType
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func syncDeleteUnspecified(
        _ db: Database,
        _ worksiteId: Int64,
        _ networkIds: [Int64]
    ) throws {
        try WorkTypeRecord.all()
            .filter(Columns.worksiteId == worksiteId && networkIds.contains(Columns.networkId) == false)
            .deleteAll(db)
    }

    func syncUpsert(_ db: Database) throws {
        let inserted = try insertAndFetch(db, onConflict: .ignore)
        if inserted == nil {
            try db.execute(
                sql:
                    """
                    UPDATE workType SET
                    createdAt   =COALESCE(:createdAt, createdAt),
                    orgClaim    =:orgClaim,
                    networkId   =:networkId,
                    nextRecurAt =:nextRecurAt,
                    phase       =:phase,
                    recur       =:recur,
                    status      =:status
                    WHERE worksiteId=:worksiteId AND workType=:workType
                    """,
                arguments: [
                    Columns.networkId.rawValue: networkId,
                    Columns.worksiteId.rawValue: worksiteId,
                    Columns.createdAt.rawValue: createdAt,
                    Columns.orgClaim.rawValue: orgClaim,
                    Columns.nextRecurAt.rawValue: nextRecurAt,
                    Columns.phase.rawValue: phase,
                    Columns.recur.rawValue: recur,
                    Columns.status.rawValue: status,
                    Columns.workType.rawValue: workType,
                ]
            )
        }
    }

    static func getWorkTypes(
        _ db: Database,
        _ worksiteId: Int64
    ) throws -> [String] {
        return try WorkTypeRecord
            .all()
            .select(Columns.workType, as: String.self)
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }

    internal static func getWorkTypeRecords(_ db: Database, _ worksiteId: Int64) throws -> [WorkTypeRecord] {
        try WorkTypeRecord
            .all()
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }
}

// MARK: - Form data

// sourcery: copyBuilder
struct WorksiteFormDataRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

    var id: Int64?
    let worksiteId: Int64
    let fieldKey: String
    let isBoolValue: Bool
    let valueString: String
    let valueBool: Bool

    init(
        _ id: Int64?,
        _ worksiteId: Int64,
        _ fieldKey: String,
        _ isBoolValue: Bool,
        _ valueString: String,
        _ valueBool: Bool
    ) {
        self.id = id
        self.worksiteId = worksiteId
        self.fieldKey = fieldKey
        self.isBoolValue = isBoolValue
        self.valueString = valueString
        self.valueBool = valueBool
    }

    func asExternalModel() -> WorksiteFormValue {
        WorksiteFormValue(
            isBoolean: isBoolValue,
            valueString: valueString,
            valueBoolean: valueBool
        )
    }
}

extension WorksiteFormDataRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksiteFormData"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             worksiteId,
             fieldKey,
             isBoolValue,
             valueString,
             valueBool
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func deleteUnspecifiedKeys(
        _ db: Database,
        _ worksiteId: Int64,
        _ fieldKeys: [String]
    ) throws {
        try WorksiteFormDataRecord.all()
            .filter(Columns.worksiteId == worksiteId && fieldKeys.contains(Columns.fieldKey) == false)
            .deleteAll(db)
    }

    static func getDataKeys(
        _ db: Database,
        _ worksiteId: Int64
    ) throws -> [String] {
        return try WorksiteFormDataRecord
            .all()
            .select(Columns.fieldKey, as: String.self)
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }

    internal static func getFormData(_ db: Database, _ worksiteId: Int64) throws -> [WorksiteFormDataRecord] {
        try WorksiteFormDataRecord
            .all()
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }
}

// MARK: - Flag

// sourcery: copyBuilder
struct WorksiteFlagRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

    var id: Int64?
    let networkId: Int64
    let worksiteId: Int64
    let action: String?
    let createdAt: Date
    let isHighPriority: Bool?
    let notes: String?
    let reasonT: String
    let requestedAction: String?

    init(
        _ id: Int64? = nil,
        _ networkId: Int64,
        _ worksiteId: Int64,
        _ action: String?,
        _ createdAt: Date,
        _ isHighPriority: Bool?,
        _ notes: String?,
        _ reasonT: String,
        _ requestedAction: String?
    ) {
        self.id = id
        self.networkId = networkId
        self.worksiteId = worksiteId
        self.action = action
        self.createdAt = createdAt
        self.isHighPriority = isHighPriority
        self.notes = notes
        self.reasonT = reasonT
        self.requestedAction = requestedAction
    }

    func asExternalModel(_ translator: KeyTranslator? = nil) -> WorksiteFlag {
        WorksiteFlag(
            id: id!,
            action: action ?? "",
            createdAt: createdAt,
            isHighPriority: isHighPriority ?? false,
            notes: notes ?? "",
            reasonT: reasonT,
            reason: translator?.translate(reasonT) ?? reasonT,
            requestedAction: requestedAction ?? ""
        )
    }
}

extension WorksiteFlagRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksiteFlag"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             networkId,
             worksiteId,
             action,
             createdAt,
             isHighPriority,
             notes,
             reasonT,
             requestedAction
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static func syncDeleteUnspecified(
        _ db: Database,
        _ worksiteId: Int64,
        _ reasons: [String]
    ) throws {
        try WorksiteFlagRecord.all()
            .filter(Columns.worksiteId == worksiteId && reasons.contains(Columns.reasonT) == false)
            .deleteAll(db)
    }

    static func getReasons(
        _ db: Database,
        _ worksiteId: Int64
    ) throws -> [String] {
        return try WorksiteFlagRecord
            .all()
            .select(Columns.reasonT, as: String.self)
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }

    internal static func getFlags(_ db: Database, _ worksiteId: Int64) throws -> [WorksiteFlagRecord] {
        try WorksiteFlagRecord
            .all()
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }
}

// MARK: - Note

// sourcery: copyBuilder
struct WorksiteNoteRecord : Identifiable, Equatable {
    static let worksite = belongsTo(WorksiteRootRecord.self)

    var id: Int64?
    let localGlobalUuid: String
    let networkId: Int64
    let worksiteId: Int64
    let createdAt: Date
    let isSurvivor: Bool
    let note: String

    init(
        _ id: Int64?,
        _ localGlobalUuid: String,
        _ networkId: Int64,
        _ worksiteId: Int64,
        _ createdAt: Date,
        _ isSurvivor: Bool,
        _ note: String
    ) {
        self.id = id
        self.localGlobalUuid = localGlobalUuid
        self.networkId = networkId
        self.worksiteId = worksiteId
        self.createdAt = createdAt
        self.isSurvivor = isSurvivor
        self.note = note
    }

    func asExternalModel() -> WorksiteNote {
        WorksiteNote(
            id!,
            createdAt,
            isSurvivor,
            note
        )
    }
}

extension WorksiteNoteRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "worksiteNote"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             localGlobalUuid,
             networkId,
             worksiteId,
             createdAt,
             isSurvivor,
             note
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    func syncUpsert(_ db: Database) throws {
        let inserted = try insertAndFetch(db, onConflict: .ignore)
        if inserted == nil {
            try db.execute(
                sql:
                    """
                    UPDATE worksiteNote SET
                           createdAt    =:createdAt,
                           isSurvivor   =:isSurvivor,
                           note         =:note
                    WHERE worksiteId=:worksiteId AND networkId=:networkId AND localGlobalUuid=''
                    """,
                arguments: [
                    Columns.worksiteId.rawValue: worksiteId,
                    Columns.networkId.rawValue: networkId,
                    Columns.createdAt.rawValue: createdAt,
                    Columns.isSurvivor.rawValue: isSurvivor,
                    Columns.note.rawValue: note,
                ]
            )
        }
    }

    static func syncDeleteUnspecified(
        _ db: Database,
        _ worksiteId: Int64,
        _ networkIds: [Int64]
    ) throws {
        try WorksiteNoteRecord.all()
            .filter(Columns.worksiteId == worksiteId && networkIds.contains(Columns.networkId) == false)
            .deleteAll(db)
    }

    static func getNotes(
        _ db: Database,
        _ worksiteId: Int64
    ) throws -> [String] {
        return try getNotes(db, worksiteId, Date.now.addingTimeInterval(-12.hours))
    }

    static func getNotes(
        _ db: Database,
        _ worksiteId: Int64,
        _ createdAt: Date
    ) throws -> [String] {
        return try WorksiteNoteRecord
            .all()
            .select(Columns.note, as: String.self)
            .filter(Columns.worksiteId == worksiteId && Columns.createdAt > createdAt)
            .fetchAll(db)
    }


    internal static func getNoteRecords(_ db: Database, _ worksiteId: Int64) throws -> [WorksiteNoteRecord] {
        try WorksiteNoteRecord
            .all()
            .filter(Columns.worksiteId == worksiteId)
            .fetchAll(db)
    }
}
