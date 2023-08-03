import Foundation

private let defaultSvi = 1.0
private let defaultFilterDistance = 0.0

let CasesFilterMinDaysAgo = 3
let CasesFilterMaxDaysAgo = 193
private let CasesFilterDaysAgoDelta = CasesFilterMaxDaysAgo - CasesFilterMinDaysAgo
private let defaultDaysAgo = CasesFilterMaxDaysAgo

// sourcery: copyBuilder, skipCopyInit
public struct CasesFilter: Hashable, Codable {
    static func determineDaysAgo(_ daysAgoNormalized: Double) -> Int {
        CasesFilterMinDaysAgo + Int(daysAgoNormalized * Double(CasesFilterDaysAgoDelta))
            .clamp(lower: 0, upper: CasesFilterDaysAgoDelta)
    }

    let svi: Double
    let daysAgoUpdated: Int
    /// In miles. 0 is any distance.
    let distance: Double
    let isWithinPrimaryResponseArea: Bool
    let isWithinSecondaryResponseArea: Bool
    let isAssignedToMyTeam: Bool
    let isUnclaimed: Bool
    let isClaimedByMyOrg: Bool
    let isReportedByMyOrg: Bool
    let isStatusOpen: Bool
    let isStatusClosed: Bool
    @WorkTypeStatusSet
    var workTypeStatuses: Set<WorkTypeStatus>
    let isMemberOfMyOrg: Bool
    let isOlderThan60: Bool
    let hasChildrenInHome: Bool
    let isFirstResponder: Bool
    let isVeteran: Bool
    @WorksiteFlagArray
    var worksiteFlags: [WorksiteFlagType]
    let workTypes: Set<String>
    let isNoWorkType: Bool
    let createdAt: DateRange?
    let updatedAt: DateRange?

    // sourcery:begin: skipCopy
    private var isDefault: Bool { self == DefaultCasesFilter }

    private let isUpdatedDaysAgoChanged: Bool

    let isDistanceChanged: Bool

    var changeCount: Int {
        if (isDefault) { return 0 }

        var count = 0
        if (svi != defaultSvi) { count += 1 }
        if (daysAgoUpdated != defaultDaysAgo) { count += 1 }
        if (distance != defaultFilterDistance) { count += 1 }
        if (isWithinPrimaryResponseArea) { count += 1 }
        if (isWithinSecondaryResponseArea) { count += 1 }
        if (isAssignedToMyTeam) { count += 1 }
        if (isUnclaimed) { count += 1 }
        if (isClaimedByMyOrg) { count += 1 }
        if (isReportedByMyOrg) { count += 1 }
        if (isStatusOpen) { count += 1 }
        if (isStatusClosed) { count += 1 }
        if (!workTypeStatuses.isEmpty) { count += workTypeStatuses.count }
        if (isMemberOfMyOrg) { count += 1 }
        if (isOlderThan60) { count += 1 }
        if (hasChildrenInHome) { count += 1 }
        if (isFirstResponder) { count += 1 }
        if (isVeteran) { count += 1 }
        if (worksiteFlags.isNotEmpty) { count += worksiteFlags.count }
        if (!workTypes.isEmpty) { count += workTypes.count }
        if (isNoWorkType) { count += 1 }
        if (createdAt != nil) { count += 1 }
        if (updatedAt != nil) { count += 1 }

        return count
    }

    let daysAgoNormalized: Double
    // sourcery:end

    init(
        svi: Double = defaultSvi,
        daysAgoUpdated: Int = defaultDaysAgo,
        distance: Double = defaultFilterDistance,
        isWithinPrimaryResponseArea: Bool = false,
        isWithinSecondaryResponseArea: Bool = false,
        isAssignedToMyTeam: Bool = false,
        isUnclaimed: Bool = false,
        isClaimedByMyOrg: Bool = false,
        isReportedByMyOrg: Bool = false,
        isStatusOpen: Bool = false,
        isStatusClosed: Bool = false,
        workTypeStatuses: Set<WorkTypeStatus> = [],
        isMemberOfMyOrg: Bool = false,
        isOlderThan60: Bool = false,
        hasChildrenInHome: Bool = false,
        isFirstResponder: Bool = false,
        isVeteran: Bool = false,
        worksiteFlags: [WorksiteFlagType] = [],
        workTypes: Set<String> = [],
        isNoWorkType: Bool = false,
        createdAt: DateRange? = nil,
        updatedAt: DateRange? = nil
    ) {
        self.svi = svi
        self.daysAgoUpdated = daysAgoUpdated
        self.distance = distance
        self.isWithinPrimaryResponseArea = isWithinPrimaryResponseArea
        self.isWithinSecondaryResponseArea = isWithinSecondaryResponseArea
        self.isAssignedToMyTeam = isAssignedToMyTeam
        self.isUnclaimed = isUnclaimed
        self.isClaimedByMyOrg = isClaimedByMyOrg
        self.isReportedByMyOrg = isReportedByMyOrg
        self.isStatusOpen = isStatusOpen
        self.isStatusClosed = isStatusClosed
        _workTypeStatuses = WorkTypeStatusSet(workTypeStatuses)
        self.isMemberOfMyOrg = isMemberOfMyOrg
        self.isOlderThan60 = isOlderThan60
        self.hasChildrenInHome = hasChildrenInHome
        self.isFirstResponder = isFirstResponder
        self.isVeteran = isVeteran
        _worksiteFlags = WorksiteFlagArray(worksiteFlags)
        self.workTypes = workTypes
        self.isNoWorkType = isNoWorkType
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        isUpdatedDaysAgoChanged = daysAgoUpdated != defaultDaysAgo
        isDistanceChanged = distance != defaultFilterDistance
        let daysAgoRatio = Double(daysAgoUpdated - CasesFilterMinDaysAgo) / Double(CasesFilterDaysAgoDelta)
        daysAgoNormalized = daysAgoRatio.clamp(lower: 0.0, upper: 1.0)
    }

    func expandDaysAgo(daysAgoNormalized: Double) -> CasesFilter {
        copy { $0.daysAgoUpdated = CasesFilter.determineDaysAgo(daysAgoNormalized) }
    }

    /**
     * @return TRUE if values meet local filters or FALSE otherwise
     */
    func localFilter(
        compareSvi: Double,
        updatedAt: Date,
        haversineDistanceMiles: Double?
    ) -> Bool {
        if (compareSvi > svi) {
            return false
        }

        if (isUpdatedDaysAgoChanged) {
            let resultDaysAgoUpdate = updatedAt.distance(to: Date.now)
            if resultDaysAgoUpdate.days > Double(daysAgoUpdated) {
                return false
            }
        }

        if (isDistanceChanged) {
            if let haversineDistanceMiles = haversineDistanceMiles {
                if haversineDistanceMiles > distance {
                    return false
                }
            }
        }

        return true
    }

    struct DateRange: Hashable, Codable {
        let start: Date
        let end: Date
    }
}

private let DefaultCasesFilter = CasesFilter()

@propertyWrapper
struct WorkTypeStatusSet: Codable, Hashable {
    var wrappedValue: Set<WorkTypeStatus>

    init(_ value: Set<WorkTypeStatus>) {
        wrappedValue = value
    }

    init(from decoder: Decoder) throws {
        let decoder = try decoder.singleValueContainer()
        let values = try? decoder.decode(String.self)
        let statuses = values?.split(separator: ",")
            .map { String($0) }
            .compactMap { literal in statusFromLiteral(literal) }
            .filter { s in s != .unknown } ?? []
        wrappedValue = Set(statuses)
    }

    func encode(to encoder: Encoder) throws {
        let s = wrappedValue.map { $0.literal }.joined(separator: ",")
        var container = encoder.singleValueContainer()
        try container.encode(s)
    }
}

@propertyWrapper
struct WorksiteFlagArray: Codable, Hashable {
    var wrappedValue: [WorksiteFlagType]

    init(_ value: [WorksiteFlagType]) {
        wrappedValue = value
    }

    init(from decoder: Decoder) throws {
        let decoder = try decoder.singleValueContainer()
        let values = try? decoder.decode(String.self)
        wrappedValue = values?.split(separator: ",")
            .map { String($0) }
            .compactMap { literal in flagFromLiteral(literal) } ?? []
    }

    func encode(to encoder: Encoder) throws {
        let s = wrappedValue.map { $0.literal }.joined(separator: ",")
        var container = encoder.singleValueContainer()
        try container.encode(s)
    }
}
