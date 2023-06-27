import Foundation

extension NetworkWorksitePage {
    func asRecord() -> WorksiteRecord {
        let keyWorkType = newestKeyWorkType()
        return WorksiteRecord(
            id: nil,
            networkId: id,
            incidentId: incident,
            address: address,
            autoContactFrequencyT: autoContactFrequencyT,
            caseNumber: caseNumber,
            city: city,
            county: county,
            createdAt: createdAt,
            email: email,
            favoriteId: favoriteId,
            keyWorkTypeType: keyWorkType?.workType ?? "",
            keyWorkTypeOrgClaim: keyWorkType?.orgClaim,
            keyWorkTypeStatus: keyWorkType?.status ?? "",
            latitude: location.coordinates[1],
            longitude: location.coordinates[0],
            name: name,
            phone1: phone1,
            phone2: phone2,
            plusCode: plusCode,
            postalCode: postalCode ?? "",
            reportedBy: reportedBy,
            state: state,
            svi: svi == nil ? nil : Double(svi!),
            what3Words: what3words,
            updatedAt: updatedAt,
            isLocalFavorite: false
        )
    }
}

extension NetworkWorksiteFull.FlagShort {
    func asRecord() -> WorksiteFlagRecord {
        return WorksiteFlagRecord(
            id: nil,
            networkId: -1,
            worksiteId: 0,
            action: nil,
            createdAt: Date(),
            isHighPriority: reasonT == WorksiteFlagType.highPriority.literal,
            notes: nil,
            reasonT: reasonT ?? "",
            requestedAction: nil
        )
    }
}

extension NetworkWorksiteFull.WorkTypeShort {
    func asRecord() -> WorkTypeRecord {
        return WorkTypeRecord(
            id: nil,
            networkId: id,
            worksiteId: 0,
            createdAt: nil,
            orgClaim: orgClaim,
            nextRecurAt: nil,
            phase: nil,
            recur: nil,
            status: status,
            workType: workType
        )
    }
}
