import Foundation

class SnapshotWorksiteChangeSerializer: WorksiteChangeSerializer {
    private let jsonEncoder: JSONEncoder

    init() {
        jsonEncoder = JsonEncoderFactory().encoder()
    }

    func serialize(
        _ isDataChange: Bool,
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64],
        requestReason: String,
        requestWorkTypes: [String],
        releaseReason: String,
        releaseWorkTypes: [String]
    ) throws -> (Int, String) {
        let snapshotStart = worksiteStart.isNew ? nil : worksiteStart.asSnapshotModel(
            flagIdLookup: flagIdLookup,
            noteIdLookup: noteIdLookup,
            workTypeIdLookup: workTypeIdLookup
        )
        let snapshotChange = worksiteChange.asSnapshotModel(
            flagIdLookup: flagIdLookup,
            noteIdLookup: noteIdLookup,
            workTypeIdLookup: workTypeIdLookup
        )
        let change = WorksiteChange(
            isWorksiteDataChange: isDataChange,
            start: snapshotStart,
            change: snapshotChange,
            requestWorkTypes: WorkTypeTransfer(reason: requestReason, workTypes: requestWorkTypes),
            releaseWorkTypes: WorkTypeTransfer(reason: releaseReason, workTypes: releaseWorkTypes)
        )
        let serializedChange = try jsonEncoder.encodeToString(change)
        return (WorksiteChangeModelVersion, serializedChange)
    }
}

extension Worksite {
    fileprivate func asSnapshotModel(
        // ID maps are local to network
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64]
    ) -> WorksiteSnapshot {
        let formDataProcessed: [String: DynamicValue]
        if let formDataDefined = formData {
            formDataProcessed = formDataDefined
                .map { (key, value) in
                    let dv = value
                    let dynamicValue = DynamicValue(
                        valueString: dv.valueString,
                        isBool: dv.isBoolean,
                        valueBool: dv.valueBoolean
                    )
                    return (key, dynamicValue)
                }
                .associate { $0 }
        } else {
            formDataProcessed = [:]
        }
        return WorksiteSnapshot(
            core: CoreSnapshot(
                id: id,
                address: address,
                autoContactFrequencyT: autoContactFrequencyT,
                caseNumber: caseNumber,
                city: city,
                county: county,
                createdAt: createdAt,
                email: email,
                favoriteId: favoriteId,
                formData: formDataProcessed,
                incidentId: incidentId,
                // Keys to a work type in workTypes (by local ID).
                keyWorkTypeId: keyWorkType?.id,
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
                svi: svi == nil ? nil : Float(svi!),
                updatedAt: updatedAt,
                what3Words: what3Words,
                isAssignedToOrgMember: isAssignedToOrgMember
            ),
            flags: flags?.map { flag in
                let attr = flag.attr
                return FlagSnapshot(
                    localId: flag.id,
                    flag: FlagSnapshot.Flag(
                        id: flagIdLookup[flag.id] ?? -1,
                        action: flag.action,
                        createdAt: flag.createdAt,
                        isHighPriority: flag.isHighPriority,
                        notes: flag.notes,
                        reasonT: flag.reasonT,
                        reason: flag.reason,
                        requestedAction: flag.requestedAction,
                        involvesMyOrg: attr?.involvesMyOrg,
                        haveContactedOtherOrg: attr?.haveContactedOtherOrg,
                        organizationIds: attr?.organizations ?? []
                    )
                )
            } ?? [],
            notes: notes.map { note in
                NoteSnapshot(
                    localId: note.id,
                    note: NoteSnapshot.Note(
                        id: noteIdLookup[note.id] ?? -1,
                        createdAt: note.createdAt,
                        isSurvivor: note.isSurvivor,
                        note: note.note
                    )
                )
            },
            workTypes: workTypes.map { workType in
                WorkTypeSnapshot(
                    localId: workType.id,
                    workType: WorkTypeSnapshot.WorkType(
                        id: workTypeIdLookup[workType.id] ?? -1,
                        status: workType.statusLiteral,
                        workType: workType.workTypeLiteral,
                        createdAt: workType.createdAt,
                        orgClaim: workType.orgClaim,
                        nextRecurAt: workType.nextRecurAt,
                        phase: workType.phase,
                        recur: workType.recur
                    )
                )
            }
        )
    }
}
