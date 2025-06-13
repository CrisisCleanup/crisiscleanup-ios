import Foundation

// Update [NetworkWorksiteCoreData.asRecord] below with similar changes
extension NetworkWorksiteFull {
    func asRecord() -> WorksiteRecord {
        WorksiteRecord(
            id: nil,
            networkId: id,
            incidentId: incident,
            address: address,
            autoContactFrequencyT: autoContactFrequencyT,
            caseNumber: caseNumber,
            caseNumberOrder: WorksiteRecord.parseCaseNumberOrder(caseNumber),
            city: city,
            county: county ?? "",
            createdAt: nil,
            email: email,
            favoriteId: favorite?.id,
            keyWorkTypeType: newestKeyWorkType?.workType ?? "",
            keyWorkTypeOrgClaim: newestKeyWorkType?.orgClaim,
            keyWorkTypeStatus: newestKeyWorkType?.status ?? "",
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

// Copy similar changes from [NetworkWorksiteFull.asEntity] above
extension NetworkWorksiteCoreData {
    func asRecord() -> WorksiteRecord {
        WorksiteRecord(
            id: nil,
            networkId: id,
            incidentId: incident,
            address: address,
            autoContactFrequencyT: autoContactFrequencyT,
            caseNumber: caseNumber,
            caseNumberOrder: WorksiteRecord.parseCaseNumberOrder(caseNumber),
            city: city,
            county: county ?? "",
            createdAt: nil,
            email: email,
            favoriteId: favorite?.id,
            keyWorkTypeType: "",
            keyWorkTypeOrgClaim: nil,
            keyWorkTypeStatus: "",
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

extension NetworkWorksitePage {
    func asRecord() -> WorksiteRecord {
        let keyWorkType = newestKeyWorkType
        return WorksiteRecord(
            id: nil,
            networkId: id,
            incidentId: incident,
            address: address,
            autoContactFrequencyT: autoContactFrequencyT,
            caseNumber: caseNumber,
            caseNumberOrder: WorksiteRecord.parseCaseNumberOrder(caseNumber),
            city: city,
            county: county ?? "",
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

extension KeyDynamicValuePair {
    func asWorksiteRecord() -> WorksiteFormDataRecord {
        WorksiteFormDataRecord(
            id: nil,
            worksiteId: 0,
            fieldKey: key,
            isBoolValue: value.isBool,
            valueString: value.valueString,
            valueBool: value.valueBool
        )
    }
}

extension NetworkFlag {
    func asRecord() -> WorksiteFlagRecord {
        WorksiteFlagRecord(
            id: nil,
            // Incoming network ID is always defined
            networkId: id!,
            worksiteId: 0,
            action: action,
            createdAt: createdAt,
            isHighPriority: isHighPriority,
            notes: notes,
            reasonT: reasonT,
            requestedAction: requestedAction
        )
    }
}

extension NetworkNote {
    func asRecord() -> WorksiteNoteRecord {
        WorksiteNoteRecord(
            id: nil,
            localGlobalUuid: "",
            // Incoming network ID is always defined
            networkId: id!,
            worksiteId: 0,
            createdAt: createdAt,
            isSurvivor: isSurvivor,
            note: note ?? ""
        )
    }
}

extension NetworkWorksiteFull {
    func asRecords() -> WorksiteRecords {
        let core = asRecord()
        let workTypes = newestWorkTypes.map { $0.asRecord() }
        let formData = formData.map { $0.asWorksiteRecord() }
        let flags = flags.map { $0.asRecord() }
        let notes = notes.map { $0.asRecord() }
        let files = files.map { $0.asRecord() }
        return WorksiteRecords(
            core,
            flags,
            formData,
            notes,
            workTypes,
            files
        )
    }
}
