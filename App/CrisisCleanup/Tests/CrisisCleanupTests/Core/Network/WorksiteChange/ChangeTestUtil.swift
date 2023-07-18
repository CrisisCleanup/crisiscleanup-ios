import Foundation
@testable import CrisisCleanup

internal class ChangeTestUtil {
    static let createdAtA = dateNowRoundedSeconds.addingTimeInterval(-10.days)
    static let updatedAtA = createdAtA.addingTimeInterval(1.hours)
    static let createdAtB = createdAtA.addingTimeInterval(3.days)
    static let updatedAtB = createdAtB.addingTimeInterval(2.hours)
}

internal func testNetworkWorksite(
    flags: [NetworkFlag] = [],
    favorite: NetworkType? = nil,
    formData: [KeyDynamicValuePair] = [],
    notes: [NetworkNote] = [],
    keyWorkType: NetworkWorkType? = nil,
    workTypes: [NetworkWorkType] = []
) -> NetworkWorksiteFull {
    NetworkWorksiteFull(
        id: 0,
        address: "",
        autoContactFrequencyT: "",
        caseNumber: "",
        city: "",
        county: "",
        email: nil,
        events: [],
        favorite: favorite,
        files: [],
        flags: flags,
        formData: formData,
        incident: 0,
        keyWorkType: keyWorkType,
        location: NetworkWorksiteFull.Location(type: "", coordinates: []),
        name: "",
        notes: notes,
        phone1: "",
        phone2: nil,
        plusCode: nil,
        postalCode: "",
        reportedBy: nil,
        state: "",
        svi: nil,
        updatedAt: ChangeTestUtil.updatedAtA,
        what3words: nil,
        workTypes: workTypes
    )
}

internal func testCoreSnapshot(
    id: Int64 = 421,
    address: String = "",
    autoContactFrequencyT: String = "",
    caseNumber: String = "",
    city: String = "",
    county: String = "",
    createdAt: Date? = nil,
    email: String = "",
    favoriteId: Int64? = nil,
    formData: [String: DynamicValue] = [:],
    incidentId: Int64 = -1,
    keyWorkTypeId: Int64? = nil,
    latitude: Double = 0.0,
    longitude: Double = 0.0,
    name: String = "",
    networkId: Int64 = -1,
    phone1: String = "",
    phone2: String = "",
    plusCode: String = "",
    postalCode: String = "",
    reportedBy: Int64? = nil,
    state: String = "",
    svi: Float? = nil,
    updatedAt: Date? = nil,
    what3Words: String? = nil,
    isAssignedToOrgMember: Bool = false
) -> CoreSnapshot {
    CoreSnapshot(
        id: id,
        address: address,
        autoContactFrequencyT: autoContactFrequencyT,
        caseNumber: caseNumber,
        city: city,
        county: county,
        createdAt: createdAt,
        email: email,
        favoriteId: favoriteId,
        formData: formData,
        incidentId: incidentId,
        keyWorkTypeId: keyWorkTypeId,
        latitude: latitude,
        longitude: longitude,
        name: name,
        networkId: networkId,
        phone1: phone1,
        phone2: phone2,
        plusCode: plusCode,
        postalCode: postalCode,
        reportedBy: reportedBy,
        state: state,
        svi: svi,
        updatedAt: updatedAt,
        what3Words: what3Words,
        isAssignedToOrgMember: isAssignedToOrgMember
    )
}
