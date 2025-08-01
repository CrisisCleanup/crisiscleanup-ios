import Foundation

public struct NetworkWorksitesFullResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorksiteFull]?
}

// Start from worksites/api/WorksiteSerializer
// Update [NetworkWorksiteCoreData] below with similar changes
public struct NetworkWorksiteFull: Codable, Equatable {
    let id: Int64
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String
    let city: String
    let county: String?
    let email: String?
    let events: [NetworkEvent]
    let favorite: NetworkType?
    let files: [NetworkFile]?
    let flags: [NetworkFlag]
    let formData: [KeyDynamicValuePair]
    let incident: Int64
    private let keyWorkType: NetworkWorkType?
    let location: Location
    let name: String
    let notes: [NetworkNote]
    let phone1: String
    let phone1Notes: String?
    let phone2: String?
    let phone2Notes: String?
    let plusCode: String?
    let postalCode: String?
    let reportedBy: Int64?
    let state: String
    @FloatStringOptional
    var svi: Float?
    let updatedAt: Date
    let what3words: String?
    private let workTypes: [NetworkWorkType]

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case autoContactFrequencyT = "auto_contact_frequency_t"
        case caseNumber = "case_number"
        case city
        case county
        case email
        case events
        case favorite
        case files
        case flags
        case formData = "form_data"
        case incident
        case keyWorkType = "key_work_type"
        case location
        case name
        case notes
        case phone1,
             phone1Notes = "phone1_notes",
             phone2,
             phone2Notes = "phone2_notes",
             plusCode = "pluscode",
             postalCode = "postal_code",
             reportedBy = "reported_by",
             state,
             svi,
             updatedAt = "updated_at",
             what3words = "what3words",
             workTypes = "work_types"
    }

    init(
        id: Int64,
        address: String,
        autoContactFrequencyT: String,
        caseNumber: String,
        city: String,
        county: String?,
        email: String?,
        events: [NetworkEvent],
        favorite: NetworkType?,
        files: [NetworkFile],
        flags: [NetworkFlag],
        formData: [KeyDynamicValuePair],
        incident: Int64,
        keyWorkType: NetworkWorkType?,
        location: Location,
        name: String,
        notes: [NetworkNote],
        phone1: String,
        phone1Notes: String?,
        phone2: String?,
        phone2Notes: String?,
        plusCode: String?,
        postalCode: String?,
        reportedBy: Int64?,
        state: String,
        svi: Float?,
        updatedAt: Date,
        what3words: String?,
        workTypes: [NetworkWorkType]
    ) {
        self.id = id
        self.address = address
        self.autoContactFrequencyT = autoContactFrequencyT
        self.caseNumber = caseNumber
        self.city = city
        self.county = county
        self.email = email
        self.events = events
        self.favorite = favorite
        self.files = files
        self.flags = flags
        self.formData = formData
        self.incident = incident
        self.keyWorkType = keyWorkType
        self.location = location
        self.name = name
        self.notes = notes
        self.phone1 = phone1
        self.phone1Notes = phone1Notes
        self.phone2 = phone2
        self.phone2Notes = phone2Notes
        self.plusCode = plusCode
        self.postalCode = postalCode
        self.reportedBy = reportedBy
        _svi = .init(value: svi)
        self.state = state
        self.updatedAt = updatedAt
        self.what3words = what3words
        self.workTypes = workTypes
    }

    internal static func getNewestWorkTypeMap(_ workTypes: [NetworkWorkType]) -> [String: (Int, NetworkWorkType)] {
        var newMap: [String: (Int, NetworkWorkType)] = [:]
        workTypes.enumerated().forEach { (index, workType) in
            let literal = workType.workType
            let similar = newMap[literal]
            if similar == nil || workType.id! > similar!.1.id! {
                newMap[literal] = (index, workType)
            }
        }
        return newMap
    }

    internal static func getNewestWorkTypes(
        _ workTypes: [NetworkWorkType],
        _ workTypeMap: [String: (Int, NetworkWorkType)]
    ) -> [NetworkWorkType] {
        if workTypeMap.count == workTypes.count {
            return workTypes
        }
        return workTypeMap.values
            .sorted { $0.0 < $1.0 }
            .map { $0.1 }
    }

    internal static func getKeyWorkType(
        _ keyWorkType: NetworkWorkType?,
        _ workTypes: [NetworkWorkType],
        _ workTypeMap: [String: (Int, NetworkWorkType)]
    ) -> NetworkWorkType? {
        if workTypeMap.count == workTypes.count {
            return keyWorkType
        }
        if let kwt = keyWorkType {
            return workTypeMap[kwt.workType]?.1
        }
        return nil
    }

    private var newestWorkTypeMap: [String: (Int, NetworkWorkType)] {
        NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
    }

    var newestWorkTypes: [NetworkWorkType] {
        NetworkWorksiteFull.getNewestWorkTypes(
            workTypes,
            newestWorkTypeMap
        )
    }

    var newestKeyWorkType: NetworkWorkType? {
        NetworkWorksiteFull.getKeyWorkType(
            keyWorkType,
            workTypes,
            newestWorkTypeMap
        )
    }

    public struct Location: Codable, Equatable {
        let type: String
        let coordinates: [Double]
    }

    public struct Time: Codable, Equatable {
        let id: Int64
        let createdByName: String?
        let createdByOrg: Int64?
        let seconds: Int
        let volunteers: Int
        let worksite: Int

        enum CodingKeys: String, CodingKey {
            case id
            case createdByName = "created_by_name"
            case createdByOrg = "created_by_org"
            case seconds
            case volunteers
            case worksite
        }
    }

    public struct KeyWorkTypeShort: Codable, Equatable {
        let workType: String
        let orgClaim: Int64?
        let status: String

        enum CodingKeys: String, CodingKey {
            case workType = "work_type"
            case orgClaim = "claimed_by"
            case status
        }
    }

    public struct WorkTypeShort: Codable, Equatable {
        let id: Int64
        let workType: String
        let orgClaim: Int64?
        let status: String

        enum CodingKeys: String, CodingKey {
            case id
            case workType = "work_type"
            case orgClaim = "claimed_by"
            case status
        }
    }

    public struct FlagShort: Codable, Equatable {
        let isHighPriority: Bool?
        let reasonT: String?
        let invalidatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case isHighPriority = "is_high_priority"
            case reasonT = "reason_t"
            case invalidatedAt = "flag_invalidated_at"
        }
    }
}

public struct NetworkWorksitesShortResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorksiteShort]?
}

public struct NetworkWorksiteLocationSearchResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorksiteLocationSearch]?
}

typealias NetworkWorkTypeShort = NetworkWorksiteFull.WorkTypeShort
typealias NetworkKeyWorkTypeShort = NetworkWorksiteFull.KeyWorkTypeShort

public struct NetworkWorksiteShort: Codable, Equatable {
    let id: Int64
    let address: String
    let caseNumber: String
    let city: String
    let county: String?
    // Full does not have this field. Updates should not overwrite
    let createdAt: Date
    // Differs from full
    let favoriteId: Int64?
    let flags: [NetworkWorksiteFull.FlagShort]
    let incident: Int64
    private let keyWorkType: NetworkWorksiteFull.KeyWorkTypeShort?
    let location: NetworkWorksiteFull.Location
    let name: String
    let postalCode: String?
    let state: String
    @FloatStringOptional
    var svi: Float?
    let updatedAt: Date
    private let workTypes: [NetworkWorksiteFull.WorkTypeShort]

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case caseNumber = "case_number"
        case city
        case county
        case createdAt = "created_at"
        case favoriteId = "favorite_id"
        case flags
        case incident
        case keyWorkType = "key_work_type"
        case location
        case name
        case postalCode = "postal_code"
        case state
        case svi
        case updatedAt = "updated_at"
        case workTypes = "work_types"
    }

    internal static func getNewestWorkTypeMap(_ workTypes: [NetworkWorkTypeShort]) -> [String: (Int, NetworkWorkTypeShort)] {
        var newMap: [String: (Int, NetworkWorkTypeShort)] = [:]
        workTypes.enumerated().forEach { (index, workType) in
            let literal = workType.workType
            let similar = newMap[literal]
            if similar == nil || workType.id > similar!.1.id {
                newMap[literal] = (index, workType)
            }
        }
        return newMap
    }

    internal static func getNewestWorkTypes(
        _ workTypes: [NetworkWorkTypeShort],
        _ workTypeMap: [String: (Int, NetworkWorkTypeShort)]
    ) -> [NetworkWorkTypeShort] {
        if workTypeMap.count == workTypes.count {
            return workTypes
        }
        return workTypeMap.values
            .sorted { $0.0 < $1.0}
            .map { $0.1 }
    }

    internal static func getKeyWorkType(
        _ keyWorkType: NetworkKeyWorkTypeShort?,
        _ workTypes: [NetworkWorkTypeShort],
        _ workTypeMap: [String: (Int, NetworkWorkTypeShort)]
    ) -> NetworkKeyWorkTypeShort? {
        if workTypeMap.count == workTypes.count {
            return keyWorkType
        }
        if keyWorkType != nil,
           let kwt = workTypeMap[keyWorkType!.workType]?.1 {
            return NetworkWorksiteFull.KeyWorkTypeShort(
                workType: kwt.workType,
                orgClaim: kwt.orgClaim,
                status: kwt.status
            )
        }
        return nil
    }

    private var newsetWorkTypeMap: [String: (Int, NetworkWorkTypeShort)] {
        NetworkWorksiteShort.getNewestWorkTypeMap(workTypes)
    }

    var newestWorkTypes: [NetworkWorkTypeShort] {
        NetworkWorksiteShort.getNewestWorkTypes(
            workTypes,
            newsetWorkTypeMap
        )
    }

    var newestKeyWorkType: NetworkKeyWorkTypeShort? {
        NetworkWorksiteShort.getKeyWorkType(
            keyWorkType,
            workTypes,
            newsetWorkTypeMap
        )
    }
}

protocol WorksiteDataResult {
    associatedtype T

    var count: Int? { get }
    var data: [T]? { get }
}

protocol WorksiteDataSubset {
    var id: Int64 { get }
    var updatedAt: Date { get }
}

public struct NetworkWorksitesPageResult: Codable, Equatable, WorksiteDataResult {
    typealias T = NetworkWorksitePage

    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorksitePage]?

    var data: [NetworkWorksitePage]? { results }
}

// Copy similar changes from [NetworkWorksiteShort] above
public struct NetworkWorksitePage: Codable, Equatable, WorksiteDataSubset {
    let id: Int64
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String
    let city: String
    let county: String?
    // Full does not have this field. Updates should not overwrite
    var createdAt: Date
    let email: String?
    // Differs from full
    let favoriteId: Int64?
    let flags: [NetworkWorksiteFull.FlagShort]
    let incident: Int64
    private let keyWorkType: NetworkWorksiteFull.KeyWorkTypeShort?
    let location: NetworkWorksiteFull.Location
    let name: String
    let phone1: String
    let phone1Notes: String?
    let phone2: String?
    let phone2Notes: String?
    let plusCode: String?
    let postalCode: String?
    let reportedBy: Int64?
    let state: String
    @FloatStringOptional
    var svi: Float?
    var updatedAt: Date
    let what3words: String?
    private let workTypes: [NetworkWorksiteFull.WorkTypeShort]
    let photoCount: Int?

    enum CodingKeys: String, CodingKey {
        case id,
             address,
             autoContactFrequencyT = "auto_contact_frequency_t",
             caseNumber = "case_number",
             city,
             county,
             createdAt = "created_at",
             email,
             favoriteId = "favorite_id",
             flags,
             incident,
             keyWorkType = "key_work_type",
             location,
             name,
             phone1,
             phone1Notes = "phone1_notes",
             phone2,
             phone2Notes = "phone2_notes",
             plusCode = "pluscode",
             postalCode = "postal_code",
             reportedBy = "reported_by",
             state,
             svi,
             updatedAt = "updated_at",
             what3words = "what3words",
             workTypes = "work_types",
             photoCount = "photos_count"
    }

    private var newsetWorkTypeMap: [String: (Int, NetworkWorkTypeShort)] {
        NetworkWorksiteShort.getNewestWorkTypeMap(workTypes)
    }

    var newestWorkTypes: [NetworkWorksiteFull.WorkTypeShort] {
        NetworkWorksiteShort.getNewestWorkTypes(
            workTypes,
            newsetWorkTypeMap
        )
    }

    var newestKeyWorkType: NetworkWorksiteFull.KeyWorkTypeShort? {
        NetworkWorksiteShort.getKeyWorkType(
            keyWorkType,
            workTypes,
            newsetWorkTypeMap
        )
    }
}

public struct NetworkWorksitesCoreDataResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorksiteCoreData]?
}

// Copy similar changes from [NetworkWorksiteFull] above
public struct NetworkWorksiteCoreData: Codable, Equatable {
    let id: Int64
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String
    let city: String
    let county: String?
    let email: String?
    let favorite: NetworkType?
    let flags: [NetworkFlag]
    let formData: [KeyDynamicValuePair]
    let incident: Int64
    let location: NetworkWorksiteFull.Location
    let name: String
    let notes: [NetworkNote]
    let phone1: String
    let phone1Notes: String?
    let phone2: String?
    let phone2Notes: String?
    let plusCode: String?
    let postalCode: String?
    let reportedBy: Int64?
    let state: String
    @FloatStringOptional
    var svi: Float?
    let updatedAt: Date
    let what3words: String?
    private let workTypes: [NetworkWorkType]

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case autoContactFrequencyT = "auto_contact_frequency_t"
        case caseNumber = "case_number"
        case city
        case county
        case email
        case favorite
        case flags
        case formData = "form_data"
        case incident
        case location
        case name
        case notes
        case phone1,
             phone1Notes = "phone1_notes",
             phone2,
             phone2Notes = "phone2_notes",
             plusCode = "pluscode",
             postalCode = "postal_code",
             reportedBy = "reported_by",
             state,
             svi,
             updatedAt = "updated_at",
             what3words = "what3words",
             workTypes = "work_types"
    }

    private var newestWorkTypeMap: [String: (Int, NetworkWorkType)] {
        NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
    }

    var newestWorkTypes: [NetworkWorkType] {
        NetworkWorksiteFull.getNewestWorkTypes(
            workTypes,
            newestWorkTypeMap
        )
    }
}

@propertyWrapper
struct FloatStringOptional: Codable, Equatable {
    var wrappedValue: Float?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Float.self) {
            wrappedValue = value
        } else if let s = try? container.decode(String.self) {
            wrappedValue = Float(s)
        } else {
            wrappedValue = nil
        }
    }

    init(value: Float?) {
        wrappedValue = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = wrappedValue {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}
