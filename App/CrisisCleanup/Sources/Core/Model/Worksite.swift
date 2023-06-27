import Foundation

enum AutoContactFrequency: String, Identifiable, CaseIterable {
    case none,
         often,
         notOften,
         never

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .none: return ""
        case .often: return "formOptions.often"
        case .notOften: return "formOptions.not_often"
        case .never: return "formOptions.never"
        }
    }
}

private let autoContactFrequencyLookup = AutoContactFrequency.allCases.associateBy{ $0.literal }

// sourcery: copyBuilder, skipCopyInit
public struct Worksite {
    let id: Int64
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String
    let city: String
    let county: String
    let createdAt: Date?
    let email: String?
    let favoriteId: Int64?
    let files: [NetworkImage]
    let flags: [WorksiteFlag]?
    let formData: [String: WorksiteFormValue]?
    let incidentId: Int64
    let keyWorkType: WorkType?
    let latitude: Double
    let longitude: Double
    let name: String
    let networkId: Int64
    let notes: [WorksiteNote]
    let phone1: String
    let phone2: String
    let plusCode: String?
    let postalCode: String
    let reportedBy: Int64?
    let state: String
    let svi: Double?
    let updatedAt: Date?
    let what3Words: String?
    let workTypes: [WorkType]
    let workTypeRequests: [WorkTypeRequest]
    /**
     * Local state of favorite when editing a worksite
     *
     * Has precedent over [favoriteId]. If [favoriteId] is defined but this is false it means the favorite was untoggled (or member flag was unchecked).
     */
    let isAssignedToOrgMember: Bool

    static func autoContactFrequency(_ literal: String) -> AutoContactFrequency {
        autoContactFrequencyLookup[literal] ?? .none
    }

    // sourcery:begin: skipCopy
    let autoContactFrequency: AutoContactFrequency

    var isNew: Bool { id <= 0 }

    var isLocalFavorite: Bool { isAssignedToOrgMember }

    var hasHighPriorityFlag: Bool {
        flags?.contains(where: { $0.isHighPriorityFlag }) ?? false
    }
    var hasWrongLocationFlag: Bool {
        flags?.contains(where: { $0.isWrongLocationFlag }) ?? false
    }

    var crossStreetNearbyLandmark: String {
        formData?[CROSS_STREET_FIELD_KEY]?.valueString ?? ""
    }
    // sourcery:end

    private func toggleFlag(_ flag: WorksiteFlagType) -> Worksite {
        let flagReason = flag.literal
        let toggledFlags = {
            if flags?.contains(where: { $0.reasonT == flagReason }) == true {
                return flags?.filter({ $0.reasonT != flagReason })
            } else {
                let addFlag = WorksiteFlag.flag(reasonT: flagReason)
                return (flags ?? []) + [addFlag]
            }
        }()
        return copy {
            $0.flags = toggledFlags
        }
    }

    init(
        id: Int64,
        address: String,
        autoContactFrequencyT: String,
        caseNumber: String,
        city: String,
        county: String,
        createdAt: Date?,
        email: String? = nil,
        favoriteId: Int64?,
        files: [NetworkImage] = [],
        flags: [WorksiteFlag]? = nil,
        formData: [String : WorksiteFormValue]? = nil,
        incidentId: Int64,
        keyWorkType: WorkType?,
        latitude: Double,
        longitude: Double,
        name: String,
        networkId: Int64,
        notes: [WorksiteNote] = [],
        phone1: String,
        phone2: String,
        plusCode: String? = nil,
        postalCode: String,
        reportedBy: Int64?,
        state: String,
        svi: Double?,
        updatedAt: Date?,
        what3Words: String? = nil,
        workTypes: [WorkType],
        workTypeRequests: [WorkTypeRequest] = [],
        isAssignedToOrgMember: Bool = false
    ) {
        self.id = id
        self.address = address
        self.autoContactFrequencyT = autoContactFrequencyT
        self.autoContactFrequency = Worksite.autoContactFrequency(autoContactFrequencyT)
        self.caseNumber = caseNumber
        self.city = city
        self.county = county
        self.createdAt = createdAt
        self.email = email
        self.favoriteId = favoriteId
        self.files = files
        self.flags = flags
        self.formData = formData
        self.incidentId = incidentId
        self.keyWorkType = keyWorkType
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.networkId = networkId
        self.notes = notes
        self.phone1 = phone1
        self.phone2 = phone2
        self.plusCode = plusCode
        self.postalCode = postalCode
        self.reportedBy = reportedBy
        self.state = state
        self.svi = svi
        self.updatedAt = updatedAt
        self.what3Words = what3Words
        self.workTypes = workTypes
        self.workTypeRequests = workTypeRequests
        self.isAssignedToOrgMember = isAssignedToOrgMember
    }

    func toggleHighPriorityFlag() -> Worksite {
        toggleFlag(WorksiteFlagType.highPriority)
    }
}

let EmptyWorksite = Worksite(
    id: -1,
    address: "",
    autoContactFrequencyT: "",
    caseNumber: "",
    city: "",
    county: "",
    createdAt: Date(),
    favoriteId: nil,
    incidentId: EmptyIncident.id,
    keyWorkType: nil,
    latitude: 0.0,
    longitude: 0.0,
    name: "",
    networkId: -1,
    phone1: "",
    phone2: "",
    postalCode: "",
    reportedBy: nil,
    state: "",
    svi: nil,
    updatedAt: nil,
    workTypes: []
)

let CROSS_STREET_FIELD_KEY = "cross_street"

public struct WorksiteFormValue: Equatable {
    let isBoolean: Bool
    let valueString: String
    let valueBoolean: Bool

    static let trueValue = WorksiteFormValue(
        isBoolean: true,
        valueBoolean: true
    )

    // sourcery:begin: skipCopy
    let isBooleanTrue: Bool
    let hasValue: Bool
    // sourcery:end

    init(
        isBoolean: Bool = false,
        valueString: String = "",
        valueBoolean: Bool = false
    ) {
        self.isBoolean = isBoolean
        self.valueString = valueString
        self.valueBoolean = valueBoolean

        isBooleanTrue =  isBoolean && valueBoolean
        hasValue = isBooleanTrue || (!isBoolean && valueString.isNotBlank)
    }
}

enum WorksiteFlagType: String, Identifiable, CaseIterable {
    case highPriority,
         upsetClient,
         markForDeletion,
         reportAbuse,
         duplicate,
         wrongLocation,
         wrongIncident

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .highPriority: return "flag.worksite_high_priority"
        case .upsetClient: return "flag.worksite_upset_client"
        case .markForDeletion: return "flag.worksite_mark_for_deletion"
        case .reportAbuse: return "flag.worksite_abuse"
        case .duplicate: return "flag.duplicate"
        case .wrongLocation: return "flag.worksite_wrong_location"
        case .wrongIncident: return "flag.worksite_wrong_incident"
        }
    }
}

private let flagTypeLookup = WorksiteFlagType.allCases.associateBy{ $0.literal }

public struct WorksiteFlag: Equatable {
    let id: Int64
    let action: String
    let createdAt: Date
    let isHighPriority: Bool
    let notes: String
    let reasonT: String
    let reason: String
    let requestedAction: String

    internal static func flag(
        reasonT: String,
        reason: String = "",
        notes: String = "",
        requestedAction: String = "",
        isHighPriorityBool: Bool = false
    ) -> WorksiteFlag {
        WorksiteFlag(
            id: 0,
            action: "",
            createdAt: Date(),
            isHighPriority: isHighPriorityBool,
            notes: notes,
            reasonT: reasonT,
            reason: reason,
            requestedAction: requestedAction
        )
    }

    static func flag(
        flag: WorksiteFlagType,
        notes: String = "",
        requestedAction: String = "",
        isHighPriorityBool: Bool = false
    ) -> WorksiteFlag {
        WorksiteFlag.flag(
            reasonT: flag.literal,
            notes: notes,
            requestedAction: requestedAction,
            isHighPriorityBool: isHighPriorityBool
        )
    }

    static func highPriority() -> WorksiteFlag {
        WorksiteFlag.flag(flag: WorksiteFlagType.highPriority)
    }
    static func wrongLocation() -> WorksiteFlag {
        WorksiteFlag.flag(flag: WorksiteFlagType.wrongLocation)
    }

    // sourcery:begin: skipCopy
    let isHighPriorityFlag: Bool
    let isWrongLocationFlag: Bool
    let flagType: WorksiteFlagType?
    // sourcery:end

    init(
        id: Int64,
        action: String,
        createdAt: Date,
        isHighPriority: Bool,
        notes: String,
        reasonT: String,
        reason: String,
        requestedAction: String
    ) {
        self.id = id
        self.action = action
        self.createdAt = createdAt
        self.isHighPriority = isHighPriority
        self.notes = notes
        self.reasonT = reasonT
        self.reason = reason
        self.requestedAction = requestedAction

        isHighPriorityFlag = reasonT == WorksiteFlagType.highPriority.literal
        isWrongLocationFlag = reasonT == WorksiteFlagType.wrongLocation.literal
        flagType = flagTypeLookup[reasonT]
    }
}

public struct WorksiteNote: Equatable {
    let id: Int64
    let createdAt: Date
    let isSurvivor: Bool
    let note: String

    static func create(_ isSurvivor: Bool = false) -> WorksiteNote {
        WorksiteNote(
            0,
            Date(),
            isSurvivor,
            ""
        )
    }

    init(
        _ id: Int64,
        _ createdAt: Date,
        _ isSurvivor: Bool,
        _ note: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isSurvivor = isSurvivor
        self.note = note
    }
}

extension [WorksiteNote] {
    var hasSurvivorNote: Bool { contains { $0.isSurvivor } }
}
