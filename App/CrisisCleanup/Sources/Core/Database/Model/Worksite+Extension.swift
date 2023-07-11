import Foundation

extension Worksite {
    func asRecords(
        _ uuidGenerator: UuidGenerator,
        _ primaryWorkType: WorkType,
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64]
    ) -> EditWorksiteRecords {
        let modifiedAt = updatedAt ?? Date.now

        let coreRecord = WorksiteRecord(
            id: id,
            networkId: networkId,
            incidentId: incidentId,
            address: address,
            autoContactFrequencyT: autoContactFrequencyT,
            caseNumber: caseNumber,
            city: city,
            county: county,
            createdAt: createdAt,
            email: email,
            favoriteId: favoriteId,
            keyWorkTypeType: primaryWorkType.workTypeLiteral,
            keyWorkTypeOrgClaim: primaryWorkType.orgClaim,
            keyWorkTypeStatus: primaryWorkType.statusLiteral,
            latitude: latitude,
            longitude: longitude,
            name: name,
            phone1: phone1,
            phone2: phone2,
            plusCode: plusCode,
            postalCode: postalCode,
            reportedBy: reportedBy,
            state: state,
            svi: svi,
            what3Words: what3Words ?? "",
            updatedAt: modifiedAt,
            isLocalFavorite: isLocalFavorite
        )

        let flagsRecords = flags?.map { flag in
            let networkId = flagIdLookup[flag.id] ?? -1
            return WorksiteFlagRecord(
                id: flag.id <= 0 ? nil : flag.id,
                networkId: networkId,
                worksiteId: id,
                action: flag.action,
                createdAt: flag.createdAt,
                isHighPriority: flag.isHighPriority,
                notes: flag.notes,
                reasonT: flag.reasonT,
                requestedAction: flag.requestedAction
            )
        }

        let formDataRecords = formData?.map { entry in
            let formDataValue = entry.value
            return WorksiteFormDataRecord(
                id: nil,
                worksiteId: id,
                fieldKey: entry.key,
                isBoolValue: formDataValue.isBoolean,
                valueString: formDataValue.valueString,
                valueBool: formDataValue.valueBoolean
            )
        }

        let notesRecords = notes.map { note in
            let networkId = noteIdLookup[note.id] ?? -1
            let isNew = networkId < 0
            return WorksiteNoteRecord(
                id: note.id <= 0 ? nil : note.id,
                localGlobalUuid: isNew ? uuidGenerator.uuid() : "",
                networkId: networkId,
                worksiteId: id,
                createdAt: note.createdAt,
                isSurvivor: note.isSurvivor,
                note: note.note
            )
        }

        let workTypesRecords = workTypes.map { workType in
            let networkId = workTypeIdLookup[workType.id] ?? -1
            return WorkTypeRecord(
                id: workType.id <= 0 ? nil : workType.id,
                networkId: networkId,
                worksiteId: id,
                createdAt: workType.createdAt,
                orgClaim: workType.orgClaim,
                nextRecurAt: workType.nextRecurAt,
                phase: workType.phase,
                recur: workType.recur,
                status: workType.statusLiteral,
                workType: workType.workTypeLiteral
            )
        }

        return EditWorksiteRecords(
            core: coreRecord,
            flags: flagsRecords ?? [],
            formData: formDataRecords ?? [],
            notes: notesRecords,
            workTypes: workTypesRecords
        )
    }
}

struct EditWorksiteRecords {
    let core: WorksiteRecord
    let flags: [WorksiteFlagRecord]
    let formData: [WorksiteFormDataRecord]
    let notes: [WorksiteNoteRecord]
    let workTypes: [WorkTypeRecord]
}
