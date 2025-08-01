// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension CoreSnapshot {
    // A default style constructor for the .copy fn to use
    init(
        id: Int64,
        address: String,
        autoContactFrequencyT: String,
        caseNumber: String,
        city: String,
        county: String,
        createdAt: Date?,
        email: String?,
        favoriteId: Int64?,
        formData: [String: DynamicValue],
        incidentId: Int64,
        keyWorkTypeId: Int64?,
        latitude: Double,
        longitude: Double,
        name: String,
        networkId: Int64,
        phone1: String,
        phone1Notes: String?,
        phone2: String,
        phone2Notes: String?,
        plusCode: String?,
        postalCode: String,
        reportedBy: Int64?,
        state: String,
        svi: Float?,
        updatedAt: Date?,
        what3Words: String?,
        isAssignedToOrgMember: Bool,
        // This is to prevent overriding the default init if it exists already
        forCopyInit: Void? = nil
    ) {
        self.id = id
        self.address = address
        self.autoContactFrequencyT = autoContactFrequencyT
        self.caseNumber = caseNumber
        self.city = city
        self.county = county
        self.createdAt = createdAt
        self.email = email
        self.favoriteId = favoriteId
        self.formData = formData
        self.incidentId = incidentId
        self.keyWorkTypeId = keyWorkTypeId
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.networkId = networkId
        self.phone1 = phone1
        self.phone1Notes = phone1Notes
        self.phone2 = phone2
        self.phone2Notes = phone2Notes
        self.plusCode = plusCode
        self.postalCode = postalCode
        self.reportedBy = reportedBy
        self.state = state
        self.svi = svi
        self.updatedAt = updatedAt
        self.what3Words = what3Words
        self.isAssignedToOrgMember = isAssignedToOrgMember
    }

    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> CoreSnapshot {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toCoreSnapshot()
    }

    struct Builder {
        var id: Int64
        var address: String
        var autoContactFrequencyT: String
        var caseNumber: String
        var city: String
        var county: String
        var createdAt: Date?
        var email: String?
        var favoriteId: Int64?
        var formData: [String: DynamicValue]
        var incidentId: Int64
        var keyWorkTypeId: Int64?
        var latitude: Double
        var longitude: Double
        var name: String
        var networkId: Int64
        var phone1: String
        var phone1Notes: String?
        var phone2: String
        var phone2Notes: String?
        var plusCode: String?
        var postalCode: String
        var reportedBy: Int64?
        var state: String
        var svi: Float?
        var updatedAt: Date?
        var what3Words: String?
        var isAssignedToOrgMember: Bool

        fileprivate init(original: CoreSnapshot) {
            self.id = original.id
            self.address = original.address
            self.autoContactFrequencyT = original.autoContactFrequencyT
            self.caseNumber = original.caseNumber
            self.city = original.city
            self.county = original.county
            self.createdAt = original.createdAt
            self.email = original.email
            self.favoriteId = original.favoriteId
            self.formData = original.formData
            self.incidentId = original.incidentId
            self.keyWorkTypeId = original.keyWorkTypeId
            self.latitude = original.latitude
            self.longitude = original.longitude
            self.name = original.name
            self.networkId = original.networkId
            self.phone1 = original.phone1
            self.phone1Notes = original.phone1Notes
            self.phone2 = original.phone2
            self.phone2Notes = original.phone2Notes
            self.plusCode = original.plusCode
            self.postalCode = original.postalCode
            self.reportedBy = original.reportedBy
            self.state = original.state
            self.svi = original.svi
            self.updatedAt = original.updatedAt
            self.what3Words = original.what3Words
            self.isAssignedToOrgMember = original.isAssignedToOrgMember
        }

        fileprivate func toCoreSnapshot() -> CoreSnapshot {
            return CoreSnapshot(
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
                phone1Notes: phone1Notes,
                phone2: phone2,
                phone2Notes: phone2Notes,
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
    }
}
