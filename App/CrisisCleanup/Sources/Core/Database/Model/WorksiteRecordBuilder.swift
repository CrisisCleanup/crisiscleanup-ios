// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorksiteRecord {
    // A default style constructor for the .copy fn to use
    init(
        id: Int64?,
        networkId: Int64,
        incidentId: Int64,
        address: String,
        autoContactFrequencyT: String?,
        caseNumber: String,
        caseNumberOrder: Int64,
        city: String,
        county: String,
        createdAt: Date?,
        email: String?,
        favoriteId: Int64?,
        keyWorkTypeType: String,
        keyWorkTypeOrgClaim: Int64?,
        keyWorkTypeStatus: String,
        latitude: Double,
        longitude: Double,
        name: String,
        phone1: String?,
        phone2: String?,
        phoneSearch: String?,
        plusCode: String?,
        postalCode: String,
        reportedBy: Int64?,
        state: String,
        svi: Double?,
        what3Words: String?,
        updatedAt: Date,
        networkPhotoCount: Int?,
        isLocalFavorite: Bool,
        // This is to prevent overriding the default init if it exists already
        forCopyInit: Void? = nil
    ) {
        self.id = id
        self.networkId = networkId
        self.incidentId = incidentId
        self.address = address
        self.autoContactFrequencyT = autoContactFrequencyT
        self.caseNumber = caseNumber
        self.caseNumberOrder = caseNumberOrder
        self.city = city
        self.county = county
        self.createdAt = createdAt
        self.email = email
        self.favoriteId = favoriteId
        self.keyWorkTypeType = keyWorkTypeType
        self.keyWorkTypeOrgClaim = keyWorkTypeOrgClaim
        self.keyWorkTypeStatus = keyWorkTypeStatus
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.phone1 = phone1
        self.phone2 = phone2
        self.phoneSearch = phoneSearch
        self.plusCode = plusCode
        self.postalCode = postalCode
        self.reportedBy = reportedBy
        self.state = state
        self.svi = svi
        self.what3Words = what3Words
        self.updatedAt = updatedAt
        self.networkPhotoCount = networkPhotoCount
        self.isLocalFavorite = isLocalFavorite
    }

    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> WorksiteRecord {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toWorksiteRecord()
    }

    struct Builder {
        var id: Int64?
        var networkId: Int64
        var incidentId: Int64
        var address: String
        var autoContactFrequencyT: String?
        var caseNumber: String
        var caseNumberOrder: Int64
        var city: String
        var county: String
        var createdAt: Date?
        var email: String?
        var favoriteId: Int64?
        var keyWorkTypeType: String
        var keyWorkTypeOrgClaim: Int64?
        var keyWorkTypeStatus: String
        var latitude: Double
        var longitude: Double
        var name: String
        var phone1: String?
        var phone2: String?
        var phoneSearch: String?
        var plusCode: String?
        var postalCode: String
        var reportedBy: Int64?
        var state: String
        var svi: Double?
        var what3Words: String?
        var updatedAt: Date
        var networkPhotoCount: Int?
        var isLocalFavorite: Bool

        fileprivate init(original: WorksiteRecord) {
            self.id = original.id
            self.networkId = original.networkId
            self.incidentId = original.incidentId
            self.address = original.address
            self.autoContactFrequencyT = original.autoContactFrequencyT
            self.caseNumber = original.caseNumber
            self.caseNumberOrder = original.caseNumberOrder
            self.city = original.city
            self.county = original.county
            self.createdAt = original.createdAt
            self.email = original.email
            self.favoriteId = original.favoriteId
            self.keyWorkTypeType = original.keyWorkTypeType
            self.keyWorkTypeOrgClaim = original.keyWorkTypeOrgClaim
            self.keyWorkTypeStatus = original.keyWorkTypeStatus
            self.latitude = original.latitude
            self.longitude = original.longitude
            self.name = original.name
            self.phone1 = original.phone1
            self.phone2 = original.phone2
            self.phoneSearch = original.phoneSearch
            self.plusCode = original.plusCode
            self.postalCode = original.postalCode
            self.reportedBy = original.reportedBy
            self.state = original.state
            self.svi = original.svi
            self.what3Words = original.what3Words
            self.updatedAt = original.updatedAt
            self.networkPhotoCount = original.networkPhotoCount
            self.isLocalFavorite = original.isLocalFavorite
        }

        fileprivate func toWorksiteRecord() -> WorksiteRecord {
            return WorksiteRecord(
                id: id,
                networkId: networkId,
                incidentId: incidentId,
                address: address,
                autoContactFrequencyT: autoContactFrequencyT,
                caseNumber: caseNumber,
                caseNumberOrder: caseNumberOrder,
                city: city,
                county: county,
                createdAt: createdAt,
                email: email,
                favoriteId: favoriteId,
                keyWorkTypeType: keyWorkTypeType,
                keyWorkTypeOrgClaim: keyWorkTypeOrgClaim,
                keyWorkTypeStatus: keyWorkTypeStatus,
                latitude: latitude,
                longitude: longitude,
                name: name,
                phone1: phone1,
                phone2: phone2,
                phoneSearch: phoneSearch,
                plusCode: plusCode,
                postalCode: postalCode,
                reportedBy: reportedBy,
                state: state,
                svi: svi,
                what3Words: what3Words,
                updatedAt: updatedAt,
                networkPhotoCount: networkPhotoCount,
                isLocalFavorite: isLocalFavorite
            )
        }
    }
}
