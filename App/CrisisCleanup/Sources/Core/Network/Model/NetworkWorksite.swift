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
    let county: String
    let email: String?
    let events: [NetworkEvent]
    let favorite: NetworkType?
    let files: [NetworkFile]
    let flags: [NetworkFlag]
    let formData: [KeyDynamicValuePair]
    let incident: Int64
    private let keyWorkType: NetworkWorkType?
    let location: Location
    let name: String
    let notes: [NetworkNote]
    let phone1: String
    let phone2: String?
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
        case phone1
        case phone2
        case plusCode = "pluscode"
        case postalCode = "postal_code"
        case reportedBy = "reported_by"
        case state
        case svi
        case updatedAt = "updated_at"
        case what3words = "what3words"
        case workTypes = "work_types"
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

    private lazy var newestWorkTypeMap = {
        return NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
    }()

    lazy private(set) var newestWorkTypes: [NetworkWorkType] = {
        return NetworkWorksiteFull.getNewestWorkTypes(
            workTypes,
            newestWorkTypeMap
        )
    }()

    lazy private(set) var newestKeyWorkType: NetworkWorkType? = {
        return NetworkWorksiteFull.getKeyWorkType(
            keyWorkType,
            workTypes,
            newestWorkTypeMap
        )
    }()

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
        // @Serializable(DateSerializer::class)
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
    let county: String
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

    private lazy var newsetWorkTypeMap = {
        return NetworkWorksiteShort.getNewestWorkTypeMap(workTypes)
    }()

    lazy var newestWorkTypes: [NetworkWorksiteFull.WorkTypeShort] = {
        return NetworkWorksiteShort.getNewestWorkTypes(
            workTypes,
            newsetWorkTypeMap
        )
    }()

    lazy var newestKeyWorkType: NetworkWorksiteFull.KeyWorkTypeShort? = {
        return NetworkWorksiteShort.getKeyWorkType(
            keyWorkType,
            workTypes,
            newsetWorkTypeMap
        )
    }()
}

public struct NetworkWorksitesPageResult: Codable, Equatable {
    let errors: [NetworkCrisisCleanupApiError]?
    let count: Int?
    let results: [NetworkWorksitePage]?
}

// Copy similar changes from [NetworkWorksiteShort] above
public struct NetworkWorksitePage: Codable, Equatable {
    let id: Int64
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String
    let city: String
    let county: String
    @DateWorksitesPage
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
    let phone2: String?
    let plusCode: String?
    let postalCode: String?
    let reportedBy: Int64?
    let state: String
    @FloatStringOptional
    var svi: Float?
    @DateWorksitesPage
    var updatedAt: Date
    let what3words: String?
    private let workTypes: [NetworkWorksiteFull.WorkTypeShort]

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case autoContactFrequencyT = "auto_contact_frequency_t"
        case caseNumber = "case_number"
        case city
        case county
        case createdAt = "created_at"
        case email
        case favoriteId = "favorite_id"
        case flags
        case incident
        case keyWorkType = "key_work_type"
        case location
        case name
        case phone1
        case phone2
        case plusCode = "pluscode"
        case postalCode = "postal_code"
        case reportedBy = "reported_by"
        case state
        case svi
        case updatedAt = "updated_at"
        case what3words = "what3words"
        case workTypes = "work_types"
    }

    private lazy var newsetWorkTypeMap = {
        return NetworkWorksiteShort.getNewestWorkTypeMap(workTypes)
    }()

    lazy var newestWorkTypes: [NetworkWorksiteFull.WorkTypeShort] = {
        return NetworkWorksiteShort.getNewestWorkTypes(
            workTypes,
            newsetWorkTypeMap
        )
    }()

    lazy var newestKeyWorkType: NetworkWorksiteFull.KeyWorkTypeShort? = {
        return NetworkWorksiteShort.getKeyWorkType(
            keyWorkType,
            workTypes,
            newsetWorkTypeMap
        )
    }()
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
    let county: String
    let email: String?
    let favorite: NetworkType?
    let flags: [NetworkFlag]
    let formData: [KeyDynamicValuePair]
    let incident: Int64
    let location: NetworkWorksiteFull.Location
    let name: String
    let notes: [NetworkNote]
    let phone1: String
    let phone2: String?
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
        case phone1
        case phone2
        case plusCode = "pluscode"
        case postalCode = "postal_code"
        case reportedBy = "reported_by"
        case state
        case svi
        case updatedAt = "updated_at"
        case what3words = "what3words"
        case workTypes = "work_types"
    }

    private lazy var newestWorkTypeMap = {
        return NetworkWorksiteFull.getNewestWorkTypeMap(workTypes)
    }()

    lazy private(set) var newestWorkTypes: [NetworkWorkType] = {
        return NetworkWorksiteFull.getNewestWorkTypes(
            workTypes,
            newestWorkTypeMap
        )
    }()
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
}

internal struct WorksitesPageDateFormatter {
    let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSxxx"
    }
}

private let iso8601DateFormatter = ISO8601DateFormatter()

@propertyWrapper
struct DateWorksitesPage: Codable, Equatable {
    static private let customDate = WorksitesPageDateFormatter()
    var wrappedValue: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            if let isoDate = iso8601DateFormatter.date(from: s) {
                wrappedValue = isoDate
                return
            } else if let customDate = DateWorksitesPage.customDate.formatter.date(from: s) {
                wrappedValue = customDate
                return
            }
        }
        throw GenericError("Failed to parse date. Is it a common format?")
    }
}
